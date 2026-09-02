//
//  RequirementsView.swift
//  Qualverum
//
//  Created by Andrew Wallace on 02/09/26.
//

import SwiftUI

struct RequirementsView: View {
    @Environment(AppState.self) private var app
    @Environment(WorkspaceService.self) private var workspace

    @State private var statusFilter: AssessmentStatus?
    @State private var categoryFilter: RequirementCategory?
    @State private var mandatoryOnly = false
    @State private var hasEvidenceOnly = false
    @State private var needsAttentionOnly = false
    @State private var sortOrder = [KeyPathComparator(\Requirement.code)]
    @State private var filter = ""

    private var tender: Tender? { workspace.store.tender(app.activeTenderID) }

    private var rows: [Requirement] {
        guard let tender else { return [] }
        let q = filter.trimmingCharacters(in: .whitespaces).lowercased()
        return tender.requirements.filter { r in
            (q.isEmpty || r.text.lowercased().contains(q) || r.code.lowercased().contains(q))
            && (statusFilter == nil || r.status == statusFilter)
            && (categoryFilter == nil || r.category == categoryFilter)
            && (!mandatoryOnly || r.isMandatory)
            && (!hasEvidenceOnly || r.evidenceCount > 0)
            && (!needsAttentionOnly || (r.status != .supported && r.isMandatory))
        }.sorted(using: sortOrder)
    }

    var body: some View {
        Group {
            if tender == nil {
                ContentUnavailableView("No Tender Selected", systemImage: "checklist")
            } else if tender?.requirements.isEmpty == true {
                ContentUnavailableView {
                    Label("No Requirements", systemImage: "checklist")
                } description: {
                    Text("Analyze this tender to extract requirements.")
                } actions: {
                    Button("Analyze Tender") { app.showAnalyze = true }
                }
            } else {
                VStack(spacing: 0) {
                    filterBar
                    Divider()
                    table
                }
            }
        }
        .navigationTitle("Requirements")
    }

    private var filterBar: some View {
        HStack {
            Picker("Status", selection: $statusFilter) {
                Text("All Status").tag(AssessmentStatus?.none)
                ForEach(AssessmentStatus.allCases) { Text($0.rawValue).tag(AssessmentStatus?.some($0)) }
            }
            Picker("Category", selection: $categoryFilter) {
                Text("All Categories").tag(RequirementCategory?.none)
                ForEach(RequirementCategory.allCases) { Text($0.rawValue).tag(RequirementCategory?.some($0)) }
            }
            Toggle("Mandatory", isOn: $mandatoryOnly)
            Toggle("Has Evidence", isOn: $hasEvidenceOnly)
            Toggle("Needs Attention", isOn: $needsAttentionOnly)
            Spacer()
            ListSearchField(text: $filter, prompt: "Filter requirements")
        }
        .toggleStyle(.button)
        .padding(8)
    }

    private var table: some View {
        @Bindable var app = app
        return Table(rows, selection: $app.selectedRequirementID, sortOrder: $sortOrder) {
            TableColumn("ID", value: \.code) { Text($0.code).monospaced() }.width(56)
            TableColumn("Requirement", value: \.text) { Text($0.text).lineLimit(2) }
            TableColumn("Category", value: \.category.rawValue) { Text($0.category.rawValue) }.width(110)
            TableColumn("Type") { $0.isMandatory ? Text("Required") : Text("Optional").foregroundStyle(.secondary) }.width(80)
            TableColumn("Status") { AssessmentStatusLabel(status: $0.status) }.width(140)
            TableColumn("Evidence") { Text("\($0.evidenceCount)") }.width(70)
        }
        .contextMenu(forSelectionType: Requirement.ID.self) { ids in
            if let id = ids.first, let r = rows.first(where: { $0.id == id }) {
                Button("Open Source") { openSource(r) }
                Button("Ask About Requirement") {
                    app.selectedRequirementID = r.id
                    app.askAbout(scope: .selectedRequirement, seed: "Why is \(r.code) \(r.status.rawValue)?")
                }
                Button("Copy Requirement") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString("\(r.code): \(r.text)", forType: .string)
                }
            }
        }
    }

    private func openSource(_ r: Requirement) {
        app.pendingDocument = PDFRequest(title: r.sourceDocument, resource: r.sourceDocument, page: r.sourcePage)
    }
}
