//
//  TenderDocumentsView.swift
//  Qualverum
//
//  Created by Andrew Wallace on 02/09/26.
//

import SwiftUI

struct TenderDocumentsView: View {
    @Environment(AppState.self) private var app
    @Environment(WorkspaceService.self) private var workspace

    @State private var sortOrder = [KeyPathComparator(\TenderDocument.imported, order: .reverse)]
    @State private var selection: TenderDocument.ID?

    private var tender: Tender? { workspace.store.tender(app.activeTenderID) }
    private var rows: [TenderDocument] { (tender?.documents ?? []).sorted(using: sortOrder) }

    var body: some View {
        Group {
            if tender == nil {
                ContentUnavailableView("No Tender Selected", systemImage: "doc.on.doc",
                                       description: Text("Choose a tender to see its documents."))
            } else if rows.isEmpty {
                ContentUnavailableView("No Documents", systemImage: "doc.on.doc",
                                       description: Text("Documents you add to this tender appear here."))
            } else {
                Table(rows, selection: $selection, sortOrder: $sortOrder) {
                    TableColumn("Name", value: \.name) { Text($0.name).fontWeight(.medium) }
                    TableColumn("Type", value: \.type)
                    TableColumn("Pages", value: \.pages) { Text("\($0.pages)") }
                    TableColumn("Version", value: \.version)
                    TableColumn("Imported", value: \.imported) { Text($0.imported.short) }
                    TableColumn("State", value: \.state.rawValue) { Text($0.state.rawValue) }
                }
                .contextMenu(forSelectionType: TenderDocument.ID.self) { ids in
                    if let id = ids.first, let d = rows.first(where: { $0.id == id }) {
                        Button("Open") { open(d) }
                    }
                } primaryAction: { ids in
                    if let id = ids.first, let d = rows.first(where: { $0.id == id }) { open(d) }
                }
            }
        }
        .navigationTitle("Tender Documents")
    }

    private func open(_ d: TenderDocument) {
        app.pendingDocument = PDFRequest(title: d.name, resource: d.sampleResource ?? d.name, page: 1)
    }
}
