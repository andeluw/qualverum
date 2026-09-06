//
//  RAGBenchmarkView.swift
//  Qualverum
//
//  Created by Andrew Wallace on 06/09/26.
//

import AppKit
import RAGCore
import SwiftUI

// A fixed set of questions we rerun against the active tender after every
// retrieval or prompt change. Expected answers and pages are the human
// reference for judging each run; the page is also a hint for spotting
// retrieval misses, not an assertion.
struct RAGBenchmarkCase: Identifiable {
    let id: String
    let question: String
    let expectedAnswer: String
    let expectedSource: String
    let expectedPage: Int?
}

struct RAGBenchmarkOutcome {
    let answer: String
    let isInsufficient: Bool
    let retrievedPages: [Int]
    let duration: TimeInterval
    let error: String?
}

enum RAGBenchmarkRating: String, CaseIterable {
    case unrated = "—"
    case correct = "Correct"
    case partial = "Partial"
    case wrong = "Wrong"
}

struct RAGBenchmarkView: View {
    @Environment(RAGService.self) private var rag
    @Environment(WorkspaceService.self) private var workspace
    @Environment(AppState.self) private var app

    @State private var outcomes: [String: RAGBenchmarkOutcome] = [:]
    @State private var ratings: [String: RAGBenchmarkRating] = [:]
    @State private var running: Set<String> = []
    @State private var runningAll = false

    private static let cases: [RAGBenchmarkCase] = [
        .init(
            id: "duration",
            question: "How long is the framework contract valid for?",
            expectedAnswer: "12 months from entry into force, automatically renewable 3 times for 12 months each unless either party gives notice at least 3 months before the end of the current period.",
            expectedSource: "Framework Contract",
            expectedPage: 5
        ),
        .init(
            id: "lots",
            question: "How many lots can a tenderer submit for?",
            expectedAnswer: "A maximum of 2 lots.",
            expectedSource: "Administrative Specifications",
            expectedPage: 6
        ),
        .init(
            id: "deposit",
            question: "What is the maximum deposit the School can pay?",
            expectedAnswer: "The deposit cannot exceed 30% of the total estimated amount.",
            expectedSource: "Framework Contract",
            expectedPage: 7
        ),
        .init(
            id: "languages",
            question: "What languages are required for the contractor's coordinator?",
            expectedAnswer: "English plus the language for the relevant lot: French (lots 1 and 6), Dutch (lot 2), German (lot 3), Italian (lot 4), Spanish (lot 5). Not all six at once.",
            expectedSource: "Technical Specifications",
            expectedPage: 5
        ),
        .init(
            id: "plane",
            question: "When is travelling by plane allowed?",
            expectedAnswer: "When the trip exceeds 400 km (800 km round trip), or shorter distances justified by cost-efficiency and specifically authorised by the School. Some Schools prohibit air travel; avoid low-cost airlines unless requested.",
            expectedSource: "Technical Specifications",
            expectedPage: 8
        ),
        .init(
            id: "audit",
            question: "What documents must the contractor retain for audit purposes, and for how long?",
            expectedAnswer: "All original documents on an appropriate medium, including digitised originals where authorised by national law, for 5 years starting from payment of the balance.",
            expectedSource: "Framework Contract",
            expectedPage: 32
        ),
        .init(
            id: "financial",
            question: "What evidence is required to prove economic and financial capacity?",
            expectedAnswer: "Profit and loss accounts and balance sheets for the last five closed years, or appropriate bank statements if unavailable; the most recent financial year must have closed within the last 18 months.",
            expectedSource: "Administrative Specifications",
            expectedPage: 15
        ),
        .init(
            id: "submission",
            question: "How must the tender be submitted?",
            expectedAnswer: "By electronic mail only, documents in PDF, except the financial offer tables which must be in both PDF and Excel.",
            expectedSource: "Invitation to Tender",
            expectedPage: 1
        ),
        .init(
            id: "ceo",
            question: "Who is the CEO of the contractor?",
            expectedAnswer: "INSUFFICIENT_EVIDENCE — the indexed documents do not identify a contractor CEO.",
            expectedSource: "None",
            expectedPage: nil
        ),
    ]

    private var tender: Tender? {
        workspace.store.tender(app.activeTenderID)
    }

    private var hasIndexedDocuments: Bool {
        tender?.documents.contains { $0.state == .indexed } ?? false
    }

    var body: some View {
        Group {
            if tender == nil {
                ContentUnavailableView(
                    "No Tender Selected",
                    systemImage: "checkmark.seal",
                    description: Text("Choose a tender with indexed documents to benchmark retrieval.")
                )
            } else {
                content
            }
        }
        .navigationTitle("RAG Benchmark")
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !hasIndexedDocuments {
                    Label(
                        "No documents are indexed for this tender yet. Runs will report insufficient evidence.",
                        systemImage: "exclamationmark.triangle"
                    )
                    .font(.callout)
                    .foregroundStyle(.secondary)
                }

                ForEach(Self.cases) { benchmark in
                    caseCard(benchmark)
                }
            }
            .padding(20)
            .frame(maxWidth: 900, alignment: .leading)
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(report(), forType: .string)
                } label: {
                    Label("Copy All Answers", systemImage: "doc.on.doc")
                }
                .disabled(outcomes.isEmpty)

                Button {
                    Task { await runAll() }
                } label: {
                    if runningAll {
                        ProgressView().controlSize(.small)
                    } else {
                        Label("Run All", systemImage: "play.fill")
                    }
                }
                .disabled(isBusy)
            }
        }
    }

    private var isBusy: Bool {
        runningAll || !running.isEmpty
    }

    // Leading glyph summarising each case at a glance. Orange marks an answer
    // whose expected page was never retrieved, the tell-tale of a retrieval miss.
    private func statusStyle(
        _ benchmark: RAGBenchmarkCase,
        _ outcome: RAGBenchmarkOutcome?
    ) -> (symbol: String, color: Color) {
        guard let outcome else {
            return ("circle.dotted", .gray)
        }

        if outcome.error != nil {
            return ("exclamationmark.triangle.fill", .red)
        }

        if outcome.isInsufficient {
            return ("questionmark.circle.fill", .gray)
        }

        if let expected = benchmark.expectedPage,
            !outcome.retrievedPages.contains(expected)
        {
            return ("exclamationmark.circle.fill", .orange)
        }

        return ("checkmark.circle.fill", .green)
    }

    private func caseCard(_ benchmark: RAGBenchmarkCase) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    let status = statusStyle(benchmark, outcomes[benchmark.id])
                    Image(systemName: status.symbol)
                        .foregroundStyle(status.color)

                    Text(benchmark.question)

                    Spacer()

                    if running.contains(benchmark.id) {
                        ProgressView().controlSize(.small)
                    } else {
                        Button("Run") {
                            Task { await run(benchmark) }
                        }
                        .disabled(isBusy)
                    }
                }

                labelled("EXPECTED", benchmark.expectedAnswer)

                Text(expectedSource(benchmark))
                    .font(.caption.monospaced())
                    .foregroundStyle(.tertiary)

                if let outcome = outcomes[benchmark.id] {
                    outcomeView(benchmark, outcome)
                    ratingPicker(benchmark)
                }
            }
            .padding(6)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func outcomeView(
        _ benchmark: RAGBenchmarkCase,
        _ outcome: RAGBenchmarkOutcome
    ) -> some View {
        Divider()

        if let error = outcome.error {
            labelled("ACTUAL", error, color: .red)
        } else {
            labelled(
                "ACTUAL",
                outcome.isInsufficient ? "INSUFFICIENT_EVIDENCE" : outcome.answer,
                color: outcome.isInsufficient ? .secondary : .primary
            )
        }

        HStack(spacing: 12) {
            Text(retrievalSummary(benchmark, outcome))
            Spacer()
            Text(String(format: "%.2f s", outcome.duration))
        }
        .font(.caption.monospaced())
        .foregroundStyle(.tertiary)
    }

    private func labelled(
        _ label: String,
        _ text: String,
        color: Color = .primary
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2.monospaced())
                .foregroundStyle(.tertiary)
            Text(text)
                .foregroundStyle(color)
                .textSelection(.enabled)
        }
    }

    private func expectedSource(_ benchmark: RAGBenchmarkCase) -> String {
        guard let page = benchmark.expectedPage else {
            return benchmark.expectedSource
        }
        return "\(benchmark.expectedSource) · p.\(page)"
    }

    private func ratingPicker(_ benchmark: RAGBenchmarkCase) -> some View {
        Picker(
            "Rating",
            selection: Binding(
                get: { ratings[benchmark.id] ?? .unrated },
                set: { ratings[benchmark.id] = $0 }
            )
        ) {
            ForEach(RAGBenchmarkRating.allCases, id: \.self) { rating in
                Text(rating.rawValue).tag(rating)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    // Where the expected page landed in the retrieved evidence, plus the
    // full list of retrieved pages for eyeballing near misses.
    private func retrievalSummary(
        _ benchmark: RAGBenchmarkCase,
        _ outcome: RAGBenchmarkOutcome
    ) -> String {
        let pages = outcome.retrievedPages
            .map(String.init)
            .joined(separator: ", ")

        guard let expected = benchmark.expectedPage else {
            return "retrieved: [\(pages)]"
        }

        if let rank = outcome.retrievedPages.firstIndex(of: expected) {
            return "expected p.\(expected) @ #\(rank + 1) · retrieved: [\(pages)]"
        }

        return "expected p.\(expected) MISSING · retrieved: [\(pages)]"
    }

    private func run(_ benchmark: RAGBenchmarkCase) async {
        guard let tenderID = tender?.id else { return }

        running.insert(benchmark.id)
        defer { running.remove(benchmark.id) }

        let startedAt = Date()

        do {
            let answer = try await rag.answer(
                question: benchmark.question,
                tenderID: tenderID,
                topK: 5
            )

            outcomes[benchmark.id] = RAGBenchmarkOutcome(
                answer: answer.text,
                isInsufficient: answer.isInsufficient,
                retrievedPages: answer.evidence.map { $0.chunk.pageNumber },
                duration: Date().timeIntervalSince(startedAt),
                error: nil
            )
        } catch {
            outcomes[benchmark.id] = RAGBenchmarkOutcome(
                answer: "",
                isInsufficient: false,
                retrievedPages: [],
                duration: Date().timeIntervalSince(startedAt),
                error: error.localizedDescription
            )
        }
    }

    // Sequential on purpose: one model instance, predictable pressure.
    private func runAll() async {
        runningAll = true
        defer { runningAll = false }

        for benchmark in Self.cases {
            await run(benchmark)
        }
    }

    private func report() -> String {
        var lines: [String] = []

        if let tender {
            lines.append("Tender: \(tender.name)")
            lines.append("")
        }

        for benchmark in Self.cases {
            lines.append("Q: \(benchmark.question)")
            lines.append("EXPECTED: \(benchmark.expectedAnswer)")

            guard let outcome = outcomes[benchmark.id] else {
                lines.append("ACTUAL: (not run)")
                lines.append("")
                continue
            }

            let rating = ratings[benchmark.id] ?? .unrated

            if let error = outcome.error {
                lines.append("ACTUAL: ERROR — \(error)")
            } else {
                lines.append("ACTUAL: \(outcome.isInsufficient ? "INSUFFICIENT_EVIDENCE" : outcome.answer)")
                lines.append(retrievalSummary(benchmark, outcome))
            }

            lines.append("RATING: \(rating.rawValue)")
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }
}
