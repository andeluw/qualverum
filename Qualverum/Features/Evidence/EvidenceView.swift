//
//  EvidenceView.swift
//  Qualverum
//
//  Created by Andrew Wallace on 02/09/26.
//

import SwiftUI

struct EvidenceView: View {
    @Environment(AppState.self) private var app
    @Environment(EvidenceService.self) private var evidenceService
    @AppStorage("confirmRemoveEvidence") private var confirmRemove = true

    @State private var sortOrder = [KeyPathComparator(\Evidence.name)]
    @State private var pendingRemoval: Evidence?
    @State private var filter = ""

    private var rows: [Evidence] {
        let q = filter.trimmingCharacters(in: .whitespaces).lowercased()
        return evidenceService.all.filter {
            q.isEmpty || $0.name.lowercased().contains(q) || $0.organization.lowercased().contains(q)
        }.sorted(using: sortOrder)
    }

    var body: some View {
        Group {
            if evidenceService.all.isEmpty {
                ContentUnavailableView {
                    Label("No Company Evidence", systemImage: "books.vertical")
                } description: {
                    Text("Add evidence documents to reuse across tenders.")
                } actions: {
                    Button("Add Evidence…") { app.showAddEvidence = true }
                }
            } else {
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        ListSearchField(text: $filter, prompt: "Filter evidence")
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    Divider()
                    table
                }
            }
        }
        .navigationTitle("Company Evidence")
        .toolbar {
            ToolbarItem { Button { app.showAddEvidence = true } label: { Label("Add Evidence", systemImage: "plus") } }
        }
        .confirmationDialog("Remove this evidence?", isPresented: .init(
            get: { pendingRemoval != nil }, set: { if !$0 { pendingRemoval = nil } }
        ), presenting: pendingRemoval) { e in
            Button("Remove", role: .destructive) { evidenceService.remove(e.id); pendingRemoval = nil }
            Button("Cancel", role: .cancel) { pendingRemoval = nil }
        } message: { e in Text(e.name) }
    }

    private var table: some View {
        @Bindable var app = app
        return Table(rows, selection: $app.selectedEvidenceID, sortOrder: $sortOrder) {
            TableColumn("Name", value: \.name) { Text($0.name).fontWeight(.medium) }
            TableColumn("Type", value: \.type.rawValue) { Text($0.type.rawValue) }
            TableColumn("Organization", value: \.organization)
            TableColumn("Date", value: \.date) { Text($0.date.short) }
            TableColumn("Expiry") { $0.expiry.map { Text($0.short) } ?? Text("—").foregroundStyle(.secondary) }
            TableColumn("Used By") { Text("\(evidenceService.usedBy($0).count)") }
            TableColumn("Status") { EvidenceStatusLabel(status: $0.status) }
        }
        .contextMenu(forSelectionType: Evidence.ID.self) { ids in
            if let id = ids.first, let e = evidenceService.all.first(where: { $0.id == id }) {
                Button("Open") { open(e) }
                Button("Ask About Evidence") {
                    app.selectedEvidenceID = e.id
                    app.askAbout(scope: .selectedEvidence, seed: "What does \(e.name) establish?")
                }
                Button("Reveal in Finder") { revealInFinder() }
                Button("Edit Metadata…") { app.selectedEvidenceID = e.id }
                Divider()
                Button("Remove…", role: .destructive) {
                    if confirmRemove { pendingRemoval = e } else { evidenceService.remove(e.id) }
                }
            }
        } primaryAction: { ids in
            if let id = ids.first, let e = evidenceService.all.first(where: { $0.id == id }) { open(e) }
        }
    }

    private func open(_ e: Evidence) {
        app.pendingDocument = PDFRequest(title: e.name, resource: e.sourceFileName, page: e.page)
    }

    private func revealInFinder() {
        // No real file yet, so just open the workspace folder.
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        if let url { NSWorkspace.shared.activateFileViewerSelecting([url]) }
    }
}
