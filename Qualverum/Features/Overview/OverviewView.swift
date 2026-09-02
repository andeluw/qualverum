//
//  OverviewView.swift
//  Qualverum
//
//  Created by Andrew Wallace on 02/09/26.
//

import SwiftUI

struct OverviewView: View {
    @Environment(AppState.self) private var app
    @Environment(WorkspaceService.self) private var workspace
    @Environment(AnalysisService.self) private var analysis

    private var tender: Tender? { workspace.store.tender(app.activeTenderID) }

    var body: some View {
        Group {
            if let tender {
                ScrollView { content(tender).padding(20) }
            } else {
                ContentUnavailableView("No Tender Selected", systemImage: "chart.bar.doc.horizontal",
                                       description: Text("Choose a tender from the selector."))
            }
        }
        .navigationTitle("Overview")
    }

    @ViewBuilder
    private func content(_ tender: Tender) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            header(tender)
            readiness(tender)

            Grid(alignment: .topLeading, horizontalSpacing: 20, verticalSpacing: 20) {
                GridRow {
                    needsAttention(tender)
                    deadlineReadiness(tender)
                }
                GridRow {
                    evidenceHealth(tender)
                    recentAnalysis(tender)
                }
            }
        }
    }

    private func card<Content: View>(_ title: String, @ViewBuilder _ content: () -> Content) -> some View {
        GroupBox {
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
        } label: {
            Text(title).font(.headline).padding(.bottom, 4)
        }
    }

    private func header(_ t: Tender) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(t.name).font(.largeTitle.bold())
            HStack(spacing: 24) {
                metaPair("Buyer", t.buyer)
                metaPair("Reference", t.reference)
                metaPair("Deadline", t.deadline.short)
            }
        }
    }

    private func metaPair(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value)
        }
    }

    private func readiness(_ t: Tender) -> some View {
        GroupBox {
            HStack(spacing: 32) {
                ReadinessGauge(value: t.readiness).frame(maxWidth: 240)
                Divider().frame(height: 44)
                countTile("\(t.requirementCount)", "Requirements", .secondary)
                countTile("\(t.supportedCount)", "Supported", .green)
                countTile("\(t.needsReviewCount)", "Needs Review", .orange)
                countTile("\(t.missingCount)", "Missing", .red)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
        }
    }

    private func countTile(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.title.monospacedDigit().bold()).foregroundStyle(color)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }

    private func needsAttention(_ t: Tender) -> some View {
        card("Needs Attention") {
            let items = t.requirements.filter { $0.status != .supported && $0.isMandatory }.prefix(5)
            if items.isEmpty {
                Text("All mandatory requirements are supported.").foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(items)) { r in
                        Button {
                            app.selectedRequirementID = r.id
                            app.sidebarSelection = .requirements
                        } label: {
                            HStack(spacing: 8) {
                                AssessmentStatusLabel(status: r.status).labelStyle(.iconOnly)
                                Text(r.code).monospaced().foregroundStyle(.secondary)
                                Text(r.text).lineLimit(1)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func deadlineReadiness(_ t: Tender) -> some View {
        card("Deadline Readiness") {
            let days = Calendar.current.dateComponents([.day], from: .now, to: t.deadline).day ?? 0
            VStack(alignment: .leading, spacing: 10) {
                LabeledContent("Submission", value: t.deadline.short)
                LabeledContent("Days Remaining", value: "\(days)")
                LabeledContent("Status") { TenderStatusLabel(status: t.status) }
                if days < 45 {
                    Label("Approaching deadline", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange).font(.callout)
                }
            }
        }
    }

    private func evidenceHealth(_ t: Tender) -> some View {
        card("Evidence Health") {
            let expiring = workspace.store.evidence.filter { $0.status == .expiringSoon || $0.status == .expired }
            VStack(alignment: .leading, spacing: 10) {
                LabeledContent("Evidence Items", value: "\(workspace.store.evidence.count)")
                LabeledContent("Expiring / Expired", value: "\(expiring.count)")
                ForEach(expiring.prefix(3)) { e in
                    HStack(spacing: 8) {
                        EvidenceStatusLabel(status: e.status).labelStyle(.iconOnly)
                        Text(e.name).lineLimit(1)
                        Spacer()
                    }
                    .font(.callout)
                }
            }
        }
    }

    private func recentAnalysis(_ t: Tender) -> some View {
        card("Recent Analysis") {
            let runs = analysis.runs(for: t.id).prefix(3)
            if runs.isEmpty {
                Text("No analysis runs yet.").foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(runs)) { run in
                        HStack {
                            Text(run.date.short)
                            Spacer()
                            runCounts(run)
                        }
                        .font(.callout)
                    }
                    Button("View History") { app.sidebarSelection = .analysisRuns }
                        .font(.callout).padding(.top, 2)
                }
            }
        }
    }

    private func runCounts(_ run: AnalysisRun) -> some View {
        HStack(spacing: 12) {
            countChip(run.supported, .green, "checkmark.circle.fill")
            countChip(run.review, .orange, "questionmark.circle.fill")
            countChip(run.missing, .red, "xmark.circle.fill")
        }
    }

    private func countChip(_ n: Int, _ color: Color, _ symbol: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: symbol).foregroundStyle(color)
            Text("\(n)").monospacedDigit()
        }
    }
}

struct OverviewInspector: View {
    @Environment(AppState.self) private var app
    @Environment(WorkspaceService.self) private var workspace

    var body: some View {
        Group {
            if let t = workspace.store.tender(app.activeTenderID) {
                Form {
                    Section("Tender") {
                        LabeledContent("Name", value: t.name)
                        LabeledContent("Buyer", value: t.buyer)
                        LabeledContent("Reference", value: t.reference)
                        LabeledContent("Deadline", value: t.deadline.short)
                        LabeledContent("Status") { TenderStatusLabel(status: t.status) }
                        LabeledContent("Version", value: t.currentVersion)
                    }
                    Section("Actions") {
                        Button("Ask About Readiness") {
                            app.askAbout(scope: .currentTender, seed: "Why are we not ready to submit?")
                        }
                        Button("Analyze Tender") { app.showAnalyze = true }
                    }
                }
                .formStyle(.grouped)
            } else {
                ContentUnavailableView("Nothing Selected", systemImage: "sidebar.right")
            }
        }
    }
}
