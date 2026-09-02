//
//  AnalysisRunsView.swift
//  Qualverum
//
//  Created by Andrew Wallace on 02/09/26.
//

import SwiftUI

struct AnalysisRunsView: View {
    @Environment(AppState.self) private var app
    @Environment(AnalysisService.self) private var analysis

    @State private var sortOrder = [KeyPathComparator(\AnalysisRun.date, order: .reverse)]
    @State private var selection: Set<AnalysisRun.ID> = []
    @State private var comparing: RunComparison?

    private var rows: [AnalysisRun] {
        analysis.runs(for: app.activeTenderID).sorted(using: sortOrder)
    }

    var body: some View {
        Group {
            if app.activeTenderID == nil {
                ContentUnavailableView("No Tender Selected", systemImage: "clock.arrow.circlepath",
                                       description: Text("Choose a tender to see its analysis runs."))
            } else if rows.isEmpty {
                ContentUnavailableView {
                    Label("No Analyses Yet", systemImage: "clock.arrow.circlepath")
                } description: {
                    Text("Analyze this tender to see its history here.")
                } actions: {
                    Button("Analyze Tender") { app.showAnalyze = true }
                }
            } else {
                Table(rows, selection: $selection, sortOrder: $sortOrder) {
                    TableColumn("Date", value: \.date) { Text($0.date.short) }
                    TableColumn("Tender Version", value: \.tenderVersion)
                    TableColumn("Evidence Version", value: \.evidenceVersion)
                    TableColumn("Configuration") { Text("\($0.configuration.embedding) · \($0.configuration.fusion)") }
                    TableColumn("Results") { resultChips($0) }.width(140)
                    TableColumn("Duration") { Text("\(Int($0.duration))s") }
                    TableColumn("Status", value: \.status.rawValue) { Text($0.status.rawValue) }
                }
            }
        }
        .navigationTitle("Analysis History")
        .toolbar {
            ToolbarItem {
                Button { compareSelected() } label: { Label("Compare", systemImage: "arrow.left.arrow.right") }
                    .help("Compare two selected runs")
                    .disabled(selection.count != 2)
            }
        }
        .onChange(of: selection) { _, sel in
            app.selectedAnalysisRunID = sel.count == 1 ? sel.first : nil
        }
        .sheet(item: $comparing) { CompareRunsSheet(a: $0.a, b: $0.b) }
    }

    private func compareSelected() {
        let picked = rows.filter { selection.contains($0.id) }.sorted { $0.date < $1.date }
        guard picked.count == 2 else { return }
        comparing = RunComparison(a: picked[0], b: picked[1])
    }

    private func resultChips(_ run: AnalysisRun) -> some View {
        HStack(spacing: 12) {
            chip(run.supported, .green, "checkmark.circle.fill", "Supported")
            chip(run.review, .orange, "questionmark.circle.fill", "Needs Review")
            chip(run.missing, .red, "xmark.circle.fill", "Missing")
        }
    }

    private func chip(_ n: Int, _ color: Color, _ symbol: String, _ label: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: symbol).foregroundStyle(color)
            Text("\(n)").monospacedDigit()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(n)")
    }
}

struct RunComparison: Identifiable {
    let id = UUID()
    let a: AnalysisRun   // earlier
    let b: AnalysisRun   // later
}

struct CompareRunsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let a: AnalysisRun
    let b: AnalysisRun

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Compare Analyses").font(.title2.bold())
                Spacer()
            }
            .padding(20)
            Divider()
            Form {
                Section {
                    LabeledContent("Earlier", value: a.date.short)
                    LabeledContent("Later", value: b.date.short)
                    LabeledContent("Tender Version", value: versions)
                }
                Section("Results") {
                    deltaRow("Supported", a.supported, b.supported)
                    deltaRow("Needs Review", a.review, b.review)
                    deltaRow("Missing", a.missing, b.missing)
                }
                Section("Run") {
                    deltaRow("Duration (s)", Int(a.duration), Int(b.duration))
                    LabeledContent("Status", value: "\(a.status.rawValue) → \(b.status.rawValue)")
                }
            }
            .formStyle(.grouped)
            Divider()
            HStack {
                Spacer()
                Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 460, height: 460)
    }

    private var versions: String {
        a.tenderVersion == b.tenderVersion ? a.tenderVersion : "\(a.tenderVersion) → \(b.tenderVersion)"
    }

    private func deltaRow(_ label: String, _ x: Int, _ y: Int) -> some View {
        LabeledContent(label) {
            HStack(spacing: 8) {
                Text("\(x) → \(y)").monospacedDigit()
                delta(y - x)
            }
        }
    }

    private func delta(_ d: Int) -> some View {
        Text(d == 0 ? "±0" : d > 0 ? "+\(d)" : "\(d)")
            .font(.caption.weight(.medium)).monospacedDigit()
            .foregroundStyle(.secondary)
    }
}

struct AnalysisRunInspector: View {
    @Environment(AppState.self) private var app
    @Environment(AnalysisService.self) private var analysis

    private var run: AnalysisRun? {
        analysis.runs.first { $0.id == app.selectedAnalysisRunID }
    }

    var body: some View {
        Group {
            if let run {
                Form {
                    Section("Analysis") {
                        LabeledContent("Date", value: run.date.short)
                        LabeledContent("Tender", value: run.tenderName)
                        LabeledContent("Status", value: run.status.rawValue)
                        LabeledContent("Duration", value: "\(Int(run.duration))s")
                    }
                    Section("Results") {
                        LabeledContent("Supported", value: "\(run.supported)")
                        LabeledContent("Needs Review", value: "\(run.review)")
                        LabeledContent("Missing", value: "\(run.missing)")
                    }
                    Section("Snapshot") {
                        LabeledContent("Tender Version", value: run.tenderVersion)
                        LabeledContent("Evidence Version", value: run.evidenceVersion)
                    }
                    Section("Retrieval Configuration") {
                        let c = run.configuration
                        LabeledContent("Chunking", value: c.chunking)
                        LabeledContent("Embedding", value: c.embedding)
                        LabeledContent("Dimension", value: "\(c.dimension)")
                        LabeledContent("Fusion", value: c.fusion)
                        LabeledContent("Rerank K", value: "\(c.rerankK)")
                        LabeledContent("Final Evidence", value: "\(c.finalEvidence)")
                    }
                }
                .formStyle(.grouped)
            } else {
                ContentUnavailableView("No Analysis Selected", systemImage: "clock.arrow.circlepath")
            }
        }
    }
}
