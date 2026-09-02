//
//  DeveloperViews.swift
//  Qualverum
//
//  Created by Andrew Wallace on 02/09/26.
//

import SwiftUI

struct RetrievalInspectorView: View {
    private let debug = MockQualverumData.retrievalDebug
    @AppStorage("showScores") private var showScores = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GroupBox("Query") { Text(debug.query).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading) }
                stage("Dense Retrieval", debug.dense)
                stage("BM25", debug.bm25)
                stage("RRF", debug.rrf)
                stage("Reranker", debug.reranked)
                stage("Final Context", debug.finalContext)
            }
            .padding(16)
        }
        .navigationTitle("Retrieval Inspector")
    }

    private func stage(_ title: String, _ rows: [RetrievalCandidate]) -> some View {
        GroupBox(title) {
            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 8) {
                GridRow {
                    Text("Chunk")
                    Text("Document")
                    Text("Page")
                    Text("Score")
                    Text("Snippet")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                Divider().gridCellUnsizedAxes(.horizontal)
                ForEach(rows) { c in
                    GridRow {
                        Text(c.chunkID).monospaced()
                        Text(c.document)
                        Text("\(c.page)")
                        showScores ? Text(String(format: "%.3f", c.score)).monospaced() : Text("—")
                        Text(c.snippet).lineLimit(2)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
    }
}

struct ChunkInspectorView: View {
    @Environment(AppState.self) private var app
    @AppStorage("showChunkIDs") private var showChunkIDs = false
    private let chunks = MockQualverumData.chunks

    var body: some View {
        @Bindable var app = app
        Table(chunks, selection: $app.selectedChunkID) {
            TableColumn("Chunk") { Text(showChunkIDs ? $0.chunkID : $0.section).monospaced() }.width(120)
            TableColumn("Document") { Text($0.document) }
            TableColumn("Page") { Text("\($0.page)") }.width(60)
        }
        .navigationTitle("Chunk Inspector")
    }
}

struct ChunkDetailInspector: View {
    @Environment(AppState.self) private var app
    @AppStorage("showChunkIDs") private var showChunkIDs = false
    @AppStorage("showTokenCounts") private var showTokenCounts = false
    @AppStorage("showRawContext") private var showRawContext = false
    private var chunk: ChunkDebugInfo? { MockQualverumData.chunks.first { $0.id == app.selectedChunkID } }

    var body: some View {
        if let c = chunk {
            Form {
                Section("Identity") {
                    if showChunkIDs {
                        LabeledContent("Chunk ID", value: c.chunkID)
                        LabeledContent("Parent ID", value: c.parentID)
                    }
                    LabeledContent("Document", value: c.document)
                    LabeledContent("Page", value: "\(c.page)")
                    LabeledContent("Section", value: c.section)
                    LabeledContent("Type", value: c.chunkType)
                    if showTokenCounts { LabeledContent("Tokens", value: "\(c.tokenCount)") }
                }
                Section("Original Text") { Text(c.originalText).textSelection(.enabled) }
                if showRawContext {
                    Section("Normalized Text") { Text(c.normalizedText).textSelection(.enabled) }
                    Section("Embedding Input") { Text(c.embeddingInput).textSelection(.enabled) }
                    Section("Parent Context") { Text(c.parentContext).textSelection(.enabled) }
                }
                Section("Metadata") {
                    ForEach(c.metadata.sorted(by: { $0.key < $1.key }), id: \.key) {
                        LabeledContent($0.key, value: $0.value)
                    }
                }
            }
            .formStyle(.grouped)
        } else {
            ContentUnavailableView("No Chunk Selected", systemImage: "square.stack.3d.up")
        }
    }
}

struct ExperimentInspectorView: View {
    private let experiments = MockQualverumData.experiments

    var body: some View {
        VStack(spacing: 0) {
            Label("Mock data — illustrative only. The retrieval stack is a hypothesis to benchmark; these are not measured results.",
                  systemImage: "flask")
                .font(.callout).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(.yellow.opacity(0.12))
            Divider()
            Table(experiments) {
                TableColumn("Experiment") { Text($0.name) }
                TableColumn("Recall@5") { pct($0.recallAt5) }
                TableColumn("Recall@10") { pct($0.recallAt10) }
                TableColumn("MRR") { num($0.mrr) }
                TableColumn("nDCG@10") { num($0.ndcgAt10) }
                TableColumn("p50") { Text("\($0.p50) ms") }
                TableColumn("p95") { Text("\($0.p95) ms") }
                TableColumn("Memory") { Text("\($0.memoryMB) MB") }
            }
        }
        .navigationTitle("Experiment Inspector (Mock)")
    }

    private func pct(_ v: Double) -> Text { Text(v, format: .percent.precision(.fractionLength(0))).monospacedDigit() }
    private func num(_ v: Double) -> Text { Text(String(format: "%.2f", v)).monospacedDigit() }
}
