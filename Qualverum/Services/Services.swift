//
//  Services.swift
//  Qualverum
//
//  Created by Andrew Wallace on 02/09/26.
//

import Foundation
import Observation

// Fake data kept in memory.
@Observable final class WorkspaceStore {
    var tenders: [Tender]
    var evidence: [Evidence]
    var runs: [AnalysisRun]
    var threads: [ChatThread]

    init() {
        let t = MockQualverumData.makeTenders()
        tenders = t
        evidence = MockQualverumData.sharedEvidence
        runs = MockQualverumData.makeRuns(tenders: t)
        threads = MockQualverumData.makeThreads(tenders: t, evidence: MockQualverumData.sharedEvidence)
    }

    func tender(_ id: UUID?) -> Tender? {
        guard let id else { return nil }
        return tenders.first { $0.id == id }
    }

    func evidence(_ id: UUID?) -> Evidence? {
        guard let id else { return nil }
        return evidence.first { $0.id == id }
    }
}

@Observable final class WorkspaceService {
    let store: WorkspaceStore
    init(store: WorkspaceStore) { self.store = store }

    var tenders: [Tender] { store.tenders }

    func addTender(_ tender: Tender) {
        store.tenders.append(tender)
    }

    func archive(_ id: UUID) {
        update(id) { $0.status = .archived }
    }

    func delete(_ id: UUID) {
        store.tenders.removeAll { $0.id == id }
    }

    func update(_ id: UUID, _ mutate: (inout Tender) -> Void) {
        guard let i = store.tenders.firstIndex(where: { $0.id == id }) else { return }
        mutate(&store.tenders[i])
        store.tenders[i].modified = .now
    }
}

@Observable final class EvidenceService {
    let store: WorkspaceStore
    init(store: WorkspaceStore) { self.store = store }

    var all: [Evidence] { store.evidence }

    func add(_ e: Evidence) { store.evidence.append(e) }
    func remove(_ id: UUID) { store.evidence.removeAll { $0.id == id } }

    func usedBy(_ evidence: Evidence) -> [Tender] {
        store.tenders.filter { t in
            t.requirements.contains { $0.assessment.evidenceIDs.contains(evidence.id) }
        }
    }
}

@Observable final class AnalysisService {
    let store: WorkspaceStore
    init(store: WorkspaceStore) { self.store = store }

    struct Stage: Identifiable, Hashable {
        let id = UUID()
        var label: String
        var done: Bool
        var active: Bool
    }

    private(set) var status: AnalysisStatus = .idle
    private(set) var stages: [Stage] = []
    private(set) var processed = 0
    private(set) var total = 0
    private(set) var lastResult: (supported: Int, review: Int, missing: Int)?
    private var task: Task<Void, Never>?

    // Starts from the saved setting, then Settings updates it live.
    var mockDelay: Double = (UserDefaults.standard.object(forKey: "mockAnalysisDelay") as? Double) ?? 0.35

    var runs: [AnalysisRun] { store.runs }

    func runs(for tenderID: UUID?) -> [AnalysisRun] {
        guard let tenderID else { return store.runs }
        return store.runs.filter { $0.tenderID == tenderID }
    }

    func analyze(_ tender: Tender) {
        guard status != .running else { return }
        let stageLabels = ["Reading documents", "Extracting requirements",
                           "Matching evidence", "Validating requirements", "Building assessments"]
        stages = stageLabels.enumerated().map { Stage(label: $1, done: false, active: $0 == 0) }
        total = max(tender.requirementCount, stageLabels.count)
        processed = 0
        status = .running
        lastResult = nil

        task = Task { @MainActor in
            for step in stages.indices {
                for i in stages.indices { stages[i].active = (i == step) }
                let perStage = max(1, total / stages.count)
                for _ in 0..<perStage {
                    // Stop here so a cancelled run never counts as finished.
                    if Task.isCancelled { return }
                    try? await Task.sleep(for: .seconds(mockDelay))
                    processed = min(processed + 1, total)
                }
                stages[step].done = true
                stages[step].active = false
            }
            processed = total
            finish(tender)
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
        if status == .running { status = .cancelled }
    }

    private func finish(_ tender: Tender) {
        status = .completed
        let result = (tender.supportedCount, tender.needsReviewCount, tender.missingCount)
        lastResult = result
        let run = AnalysisRun(
            date: .now, tenderID: tender.id, tenderName: tender.name,
            tenderVersion: tender.currentVersion,
            evidenceVersion: ISO8601DateFormatter().string(from: .now).prefix(10).description,
            configuration: .init(), supported: result.0, review: result.1, missing: result.2,
            duration: Double(total) * mockDelay, status: .completed)
        store.runs.insert(run, at: 0)
    }

    func reset() {
        status = .idle
        stages = []
        processed = 0
        total = 0
        lastResult = nil
    }
}

@Observable final class ChatService {
    let store: WorkspaceStore
    init(store: WorkspaceStore) { self.store = store }

    private(set) var pendingThreadID: UUID?

    var threads: [ChatThread] { store.threads }

    func newThread(scope: ChatScope, tenderID: UUID?) -> ChatThread {
        let thread = ChatThread(title: "New Chat", scope: scope, tenderID: tenderID, messages: [])
        store.threads.insert(thread, at: 0)
        return thread
    }

    func rename(_ id: UUID, to title: String) {
        guard let i = index(id) else { return }
        store.threads[i].title = title
    }

    func delete(_ id: UUID) {
        store.threads.removeAll { $0.id == id }
    }

    func send(_ text: String, to threadID: UUID) {
        guard let i = index(threadID) else { return }
        store.threads[i].messages.append(.init(role: .user, text: text))
        if store.threads[i].title == "New Chat" {
            store.threads[i].title = String(text.prefix(40))
        }
        pendingThreadID = threadID
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.6))
            let reply = Self.cannedAnswer(for: text)
            if let j = index(threadID) { store.threads[j].messages.append(reply) }
            pendingThreadID = nil
        }
    }

    private func index(_ id: UUID) -> Int? { store.threads.firstIndex { $0.id == id } }

    // If nothing matches, say so instead of guessing.
    static func cannedAnswer(for question: String) -> ChatMessage {
        let q = question.lowercased()
        if q.contains("r17") || q.contains("project") {
            return .init(role: .assistant,
                         text: "The tender requires two comparable projects completed within the previous three years.\n\nProject Alpha qualifies. [1]\n\nProject Beta is recent enough, but the current evidence does not establish sufficient similarity. [2]\n\nResult: Needs Review.",
                         citations: [.init(index: 1, label: "School-SIS-Case-Study.pdf · p.4", evidenceID: nil, page: 4),
                                     .init(index: 2, label: "Municipal-ERP.pdf · p.7", evidenceID: nil, page: 7)])
        }
        if q.contains("missing") || q.contains("not ready") || q.contains("readiness") {
            return .init(role: .assistant,
                         text: "Three mandatory requirements are not yet Supported: R38 (EEA hosting) has no evidence, R30 (Cyber Essentials Plus) is expired, and R17 (reference projects) needs review. [1]",
                         citations: [.init(index: 1, label: "Tender-Specification.pdf · p.44", evidenceID: nil, page: 44)])
        }
        if q.contains("expire") {
            return .init(role: .assistant,
                         text: "Professional Indemnity Insurance expires 2025-12-31 and ISO 9001 expires 2026-10-30. [1][2]",
                         citations: [.init(index: 1, label: "PI-Insurance.pdf · p.1", evidenceID: nil, page: 1),
                                     .init(index: 2, label: "ISO-9001-Certificate.pdf · p.1", evidenceID: nil, page: 1)])
        }
        if q.contains("financ") || q.contains("turnover") {
            return .init(role: .assistant,
                         text: "The 2024 audited statements show €24.6M turnover, above the €10M threshold. Prior-year turnover is not yet in evidence. [1]",
                         citations: [.init(index: 1, label: "Financials-2024.pdf · p.2", evidenceID: nil, page: 2)])
        }
        return .init(role: .assistant,
                     text: "I can't establish this from the current evidence. No indexed evidence answers this question yet, add supporting documents or narrow the scope.",
                     kind: .insufficientEvidence)
    }
}

@Observable final class DocumentService {
    func sampleURL(named resource: String?) -> URL? {
        guard let resource else { return nil }
        let base = (resource as NSString).deletingPathExtension
        return Bundle.main.url(forResource: base, withExtension: "pdf")
    }
}
