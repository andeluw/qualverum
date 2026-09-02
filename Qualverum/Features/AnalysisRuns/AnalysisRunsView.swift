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

    private var rows: [AnalysisRun] {
        analysis.runs(for: app.activeTenderID).sorted(using: sortOrder)
    }

    var body: some View {
        @Bindable var app = app
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
                Table(rows, selection: $app.selectedAnalysisRunID, sortOrder: $sortOrder) {
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
