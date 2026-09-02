//
//  AnalyzeSheet.swift
//  Qualverum
//
//  Created by Andrew Wallace on 02/09/26.
//

import SwiftUI

struct AnalyzeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var app
    @Environment(WorkspaceService.self) private var workspace
    @Environment(AnalysisService.self) private var analysis

    private var tender: Tender? { workspace.store.tender(app.activeTenderID) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            switch analysis.status {
            case .completed: completion
            case .running: progress
            case .failed: failure
            case .cancelled: cancelledState
            default: idle
            }
        }
        .padding(20)
        .frame(width: 420, height: 380)
        .onDisappear { if analysis.status != .running { analysis.reset() } }
    }

    private var idle: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Analyze Tender").font(.title2.bold())
            if let tender {
                Text(tender.name).foregroundStyle(.secondary)
                LabeledContent("Requirements", value: "\(tender.requirementCount)")
                LabeledContent("Documents", value: "\(tender.documents.count)")
            }
            Spacer()
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Analyze") { if let tender { analysis.analyze(tender) } }
                    .keyboardShortcut(.defaultAction).disabled(tender == nil)
            }
        }
    }

    private var progress: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Analyzing…").font(.title2.bold())
            ForEach(analysis.stages) { stage in
                HStack {
                    Image(systemName: stage.done ? "checkmark.circle.fill"
                          : stage.active ? "circle.dotted" : "circle")
                        .foregroundStyle(stage.done ? .green : stage.active ? .accentColor : .secondary)
                    Text(stage.label)
                        .foregroundStyle(stage.done || stage.active ? .primary : .secondary)
                    Spacer()
                }
            }
            ProgressView(value: Double(analysis.processed), total: Double(max(analysis.total, 1))) {
                Text("\(analysis.processed) / \(analysis.total)").monospacedDigit().font(.callout)
            }
            Spacer()
            HStack {
                Spacer()
                Button("Cancel Analysis", role: .cancel) { analysis.cancel() }
            }
        }
    }

    private var completion: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Analysis Complete", systemImage: "checkmark.seal.fill")
                .font(.title2.bold()).foregroundStyle(.green)
            if let r = analysis.lastResult {
                Text("\(r.supported + r.review + r.missing) requirements analyzed").foregroundStyle(.secondary)
                LabeledContent("Supported", value: "\(r.supported)")
                LabeledContent("Needs Review", value: "\(r.review)")
                LabeledContent("Missing", value: "\(r.missing)")
            }
            Spacer()
            HStack {
                Spacer()
                Button("Close") { dismiss() }
                Button("Review Results") {
                    app.sidebarSelection = .requirements
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
    }

    private var failure: some View {
        errorState("Analysis Failed", "The analysis could not complete. Check the documents and try again.")
    }

    private var cancelledState: some View {
        errorState("Analysis Cancelled", "The run was cancelled before completion.")
    }

    private func errorState(_ title: String, _ message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: "exclamationmark.triangle.fill")
                .font(.title2.bold()).foregroundStyle(.orange)
            Text(message).foregroundStyle(.secondary)
            Spacer()
            HStack {
                Spacer()
                Button("Close") { dismiss() }
                Button("Retry") { analysis.reset(); if let tender { analysis.analyze(tender) } }
                    .keyboardShortcut(.defaultAction)
            }
        }
    }
}
