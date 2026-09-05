//
//  Services.swift
//  Qualverum
//
//  Created by Andrew Wallace on 02/09/26.
//

import Foundation
import Observation
import RAGCore

// Fake data kept in memory.
@Observable final class WorkspaceStore {
    var tenders: [Tender] {
        didSet {
            saveTenders()
        }
    }
    var evidence: [Evidence]
    var runs: [AnalysisRun]
    var threads: [ChatThread]

    private let persistence: WorkspacePersistence

    init(
        persistence: WorkspacePersistence = WorkspacePersistence()
    ) {
        self.persistence = persistence

        do {
            tenders = try persistence.loadTenders()
        } catch {
            print("Failed to load workspace:", error)
            tenders = []
        }

        evidence = []
        runs = []
        threads = []
    }

    func tender(_ id: UUID?) -> Tender? {
        guard let id else { return nil }
        return tenders.first { $0.id == id }
    }

    func evidence(_ id: UUID?) -> Evidence? {
        guard let id else { return nil }
        return evidence.first { $0.id == id }
    }

    private func saveTenders() {
        do {
            try persistence.saveTenders(tenders)
        } catch {
            print("Failed to save workspace:", error)
        }
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

    func restore(_ id: UUID) {
        update(id) {
            $0.status = $0.requirements.isEmpty ? .notAnalyzed : .inReview
        }
    }

    func delete(_ id: UUID) {
        store.tenders.removeAll { $0.id == id }
    }

    func update(_ id: UUID, _ mutate: (inout Tender) -> Void) {
        guard let i = store.tenders.firstIndex(where: { $0.id == id }) else {
            return
        }
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
            t.requirements.contains {
                $0.assessment.evidenceIDs.contains(evidence.id)
            }
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
    var mockDelay: Double =
        (UserDefaults.standard.object(forKey: "mockAnalysisDelay") as? Double)
        ?? 0.35

    var runs: [AnalysisRun] { store.runs }

    func runs(for tenderID: UUID?) -> [AnalysisRun] {
        guard let tenderID else { return store.runs }
        return store.runs.filter { $0.tenderID == tenderID }
    }

    func analyze(_ tender: Tender) {
        guard status != .running else { return }
        let stageLabels = [
            "Reading documents", "Extracting requirements",
            "Matching evidence", "Validating requirements",
            "Building assessments",
        ]
        stages = stageLabels.enumerated().map {
            Stage(label: $1, done: false, active: $0 == 0)
        }
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
        var resolved = tender
        // A freshly created tender has no requirements yet; the mock pipeline fills in a
        // realistic extracted set so the New Tender flow actually lands on a matrix.
        if resolved.requirements.isEmpty {
            resolved.requirements = MockQualverumData.primaryRequirements(
                evidence: store.evidence
            )
        }
        if let i = store.tenders.firstIndex(where: { $0.id == resolved.id }) {
            store.tenders[i].requirements = resolved.requirements
            store.tenders[i].status = .inReview
            store.tenders[i].modified = .now
        }
        let result = (
            resolved.supportedCount, resolved.needsReviewCount,
            resolved.missingCount
        )
        lastResult = result
        let run = AnalysisRun(
            date: .now,
            tenderID: resolved.id,
            tenderName: resolved.name,
            tenderVersion: resolved.currentVersion,
            evidenceVersion: ISO8601DateFormatter().string(from: .now).prefix(
                10
            ).description,
            configuration: .init(),
            supported: result.0,
            review: result.1,
            missing: result.2,
            duration: Double(total) * mockDelay,
            status: .completed
        )
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

@MainActor
@Observable
final class ChatService {
    let store: WorkspaceStore

    private let rag: RAGService

    private(set) var pendingThreadID: UUID?

    init(
        store: WorkspaceStore,
        rag: RAGService
    ) {
        self.store = store
        self.rag = rag
    }

    var threads: [ChatThread] {
        store.threads
    }

    func newThread(
        scope: ChatScope,
        tenderID: UUID?
    ) -> ChatThread {
        let thread = ChatThread(
            title: "New Chat",
            scope: scope,
            tenderID: tenderID,
            messages: []
        )

        store.threads.insert(thread, at: 0)

        return thread
    }

    func rename(_ id: UUID, to title: String) {
        guard let i = index(id) else { return }
        store.threads[i].title = title
    }

    func setScope(_ scope: ChatScope, for id: UUID) {
        guard let i = index(id) else { return }
        store.threads[i].scope = scope
    }

    func delete(_ id: UUID) {
        store.threads.removeAll { $0.id == id }
    }

    func send(_ text: String, to threadID: UUID) {
        guard let i = index(threadID) else { return }

        store.threads[i].messages.append(
            ChatMessage(role: .user, text: text)
        )

        if store.threads[i].title == "New Chat" {
            store.threads[i].title = String(text.prefix(40))
        }

        let scope = store.threads[i].scope
        let tenderID = store.threads[i].tenderID

        // App keeps the full history; only the most recent
        // turns are offered to the model call.
        let history =
            store.threads[i].messages
            .dropLast()
            .suffix(4)
            .map { message in
                RAGConversationTurn(
                    role: message.role == .user ? .user : .assistant,
                    text: message.text
                )
            }

        pendingThreadID = threadID

        Task { @MainActor in
            defer {
                if pendingThreadID == threadID {
                    pendingThreadID = nil
                }
            }

            guard scope == .currentTender else {
                append(
                    ChatMessage(
                        role: .assistant,
                        text:
                            "This scope is not indexed yet. Use Current Tender for document-grounded questions in this build."
                    ),
                    to: threadID
                )

                return
            }

            guard let tenderID else {
                append(
                    ChatMessage(
                        role: .assistant,
                        text:
                            "Select a tender before asking a document-grounded question.",
                        kind: .insufficientEvidence
                    ),
                    to: threadID
                )

                return
            }

            do {
                let answer = try await rag.answer(
                    question: text,
                    tenderID: tenderID,
                    history: Array(history)
                )

                if answer.isInsufficient {
                    append(
                        ChatMessage(
                            role: .assistant,
                            text:
                                "I can't establish this from the indexed tender documents.",
                            kind: .insufficientEvidence
                        ),
                        to: threadID
                    )

                    return
                }

                append(
                    ChatMessage(
                        role: .assistant,
                        text: answer.text,
                        citations: citations(
                            from: answer.evidence,
                            tenderID: tenderID
                        )
                    ),
                    to: threadID
                )

            } catch GenerationProviderError.unavailable(let reason) {
                append(
                    ChatMessage(
                        role: .assistant,
                        text: Self.unavailableMessage(for: reason)
                    ),
                    to: threadID
                )

            } catch GenerationProviderError.contextTooLarge {
                append(
                    ChatMessage(
                        role: .assistant,
                        text:
                            "The retrieved context is too large for the on-device model. Try a more specific question."
                    ),
                    to: threadID
                )

            } catch RAGServiceError.noIndexForTender {
                append(
                    ChatMessage(
                        role: .assistant,
                        text:
                            "This tender has no indexed documents yet. Add a PDF in Tender Documents first.",
                        kind: .insufficientEvidence
                    ),
                    to: threadID
                )

            } catch RAGServiceError.noRetrievalResults {
                append(
                    ChatMessage(
                        role: .assistant,
                        text:
                            "I couldn't find relevant evidence in the indexed tender documents.",
                        kind: .insufficientEvidence
                    ),
                    to: threadID
                )

            } catch {
                append(
                    ChatMessage(
                        role: .assistant,
                        text:
                            "I couldn't answer this question.\n\n\(error.localizedDescription)"
                    ),
                    to: threadID
                )
            }
        }
    }

    private func append(_ message: ChatMessage, to threadID: UUID) {
        guard let i = index(threadID) else { return }
        store.threads[i].messages.append(message)
    }

    private func index(_ id: UUID) -> Int? {
        store.threads.firstIndex { $0.id == id }
    }

    private func citations(
        from results: [RetrievalResult],
        tenderID: UUID
    ) -> [ChatCitation] {
        results.enumerated().map {
            index,
            result in

            let chunk = result.chunk

            let documentID = UUID(
                uuidString: chunk.documentID
            )

            let document =
                store.tender(tenderID)?
                .documents
                .first {
                    $0.id == documentID
                }

            let name =
                document?.name
                ?? chunk.documentID

            return ChatCitation(
                index: index + 1,
                label:
                    "\(name) · p.\(chunk.pageNumber)",
                evidenceID: nil,
                documentID: documentID,
                storedFilename:
                    document?.storedFilename,
                page: chunk.pageNumber
            )
        }
    }

    private static func unavailableMessage(
        for reason: GenerationUnavailableReason
    ) -> String {
        switch reason {
        case .appleIntelligenceNotEnabled:
            return
                "Ask Qualverum requires Apple Intelligence. Turn on Apple Intelligence and try again."

        case .deviceNotEligible:
            return "The on-device Foundation Model isn't supported on this Mac."

        case .modelNotReady:
            return
                "The on-device Foundation Model isn't ready yet. It may still be downloading."

        case .unknown:
            return "The on-device Foundation Model is currently unavailable."
        }
    }
}

@Observable
final class DocumentService {
    private let fileStore: DocumentFileStore

    init(
        fileStore: DocumentFileStore = DocumentFileStore()
    ) {
        self.fileStore = fileStore
    }

    func url(
        for request: PDFRequest?
    ) -> URL? {
        guard let request else {
            return nil
        }

        if let storedFilename =
            request.storedFilename
        {
            let url = fileStore.url(
                for: storedFilename
            )

            if FileManager.default.fileExists(
                atPath: url.path
            ) {
                return url
            }
        }

        return sampleURL(
            named: request.resource
        )
    }

    private func sampleURL(
        named resource: String?
    ) -> URL? {
        guard let resource else {
            return nil
        }

        let base =
            (resource as NSString)
            .deletingPathExtension

        return Bundle.main.url(
            forResource: base,
            withExtension: "pdf"
        )
    }
}
