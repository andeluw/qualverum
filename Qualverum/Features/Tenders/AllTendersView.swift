//
//  AllTendersView.swift
//  Qualverum
//
//  Created by Andrew Wallace on 02/09/26.
//

import SwiftUI

struct AllTendersView: View {
    @Environment(AppState.self) private var app
    @Environment(WorkspaceService.self) private var workspace

    @State private var sortOrder = [KeyPathComparator(\Tender.deadline)]
    @State private var selection: Tender.ID?
    @State private var filter = ""
    @State private var pendingDeletion: Tender?

    private var rows: [Tender] {
        let q = filter.trimmingCharacters(in: .whitespaces).lowercased()
        let base = workspace.tenders.filter {
            q.isEmpty || $0.name.lowercased().contains(q) || $0.buyer.lowercased().contains(q)
                || $0.reference.lowercased().contains(q)
        }
        return base.sorted(using: sortOrder)
    }

    var body: some View {
        Group {
            if workspace.tenders.isEmpty {
                ContentUnavailableView {
                    Label("No Tenders", systemImage: "square.grid.2x2")
                } description: {
                    Text("Create or import a tender to begin.")
                } actions: {
                    Button("New Tender…") { app.showNewTender = true }
                }
            } else {
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        ListSearchField(text: $filter, prompt: "Filter tenders")
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    Divider()
                    table
                }
            }
        }
        .navigationTitle("All Tenders")
        .toolbar {
            ToolbarItem { Button { app.showNewTender = true } label: { Label("New Tender", systemImage: "plus") } }
        }
        .confirmationDialog("Delete this tender?", isPresented: .init(
            get: { pendingDeletion != nil }, set: { if !$0 { pendingDeletion = nil } }
        ), presenting: pendingDeletion) { t in
            Button("Delete", role: .destructive) { workspace.delete(t.id); pendingDeletion = nil }
            Button("Cancel", role: .cancel) { pendingDeletion = nil }
        } message: { t in Text("\(t.name) and its requirements will be removed. This cannot be undone.") }
    }

    private var table: some View {
        Table(rows, selection: $selection, sortOrder: $sortOrder) {
            TableColumn("Tender", value: \.name) { Text($0.name).fontWeight(.medium) }
            TableColumn("Buyer", value: \.buyer)
            TableColumn("Reference", value: \.reference)
            TableColumn("Deadline", value: \.deadline) { Text($0.deadline.short) }
            TableColumn("Requirements") { Text("\($0.requirementCount)") }
            TableColumn("Readiness") { t in
                ReadinessGauge(value: t.readiness).frame(width: 90)
            }
            TableColumn("Status") { TenderStatusLabel(status: $0.status) }
        }
        .contextMenu(forSelectionType: Tender.ID.self) { ids in
            if let id = ids.first, let t = workspace.store.tender(id) {
                Button("Open") { open(t) }
                Button("Analyze") { app.activeTenderID = t.id; app.showAnalyze = true }
                Divider()
                Button("Archive") { workspace.archive(t.id) }
                Button("Delete…", role: .destructive) { pendingDeletion = t }
            }
        } primaryAction: { ids in
            if let id = ids.first, let t = workspace.store.tender(id) { open(t) }
        }
    }

    private func open(_ t: Tender) {
        app.activeTenderID = t.id
        app.sidebarSelection = .overview
    }
}
