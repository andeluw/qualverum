//
//  TenderDocumentsView.swift
//  Qualverum
//
//  Created by Andrew Wallace on 02/09/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct TenderDocumentsView: View {
    @Environment(AppState.self) private var app
    @Environment(WorkspaceService.self) private var workspace

    @State private var sortOrder = [KeyPathComparator(\TenderDocument.imported, order: .reverse)]
    @State private var importing = false

    private var tender: Tender? { workspace.store.tender(app.activeTenderID) }
    private var rows: [TenderDocument] { (tender?.documents ?? []).sorted(using: sortOrder) }

    var body: some View {
        @Bindable var app = app
        return Group {
            if tender == nil {
                ContentUnavailableView("No Tender Selected", systemImage: "doc.on.doc",
                                       description: Text("Choose a tender to see its documents."))
            } else if rows.isEmpty {
                ContentUnavailableView {
                    Label("No Documents", systemImage: "doc.on.doc")
                } description: {
                    Text("Documents you add to this tender appear here.")
                } actions: {
                    Button("Add Documents…") { importing = true }
                }
            } else {
                Table(rows, selection: $app.selectedDocumentID, sortOrder: $sortOrder) {
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
        .toolbar {
            if tender != nil {
                ToolbarItem {
                    Button { importing = true } label: { Label("Add Documents", systemImage: "plus") }
                }
            }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.pdf], allowsMultipleSelection: true) { result in
            if case .success(let urls) = result { addDocuments(urls) }
        }
    }

    private func open(_ d: TenderDocument) {
        app.pendingDocument = PDFRequest(title: d.name, resource: d.sampleResource ?? d.name, page: 1)
    }

    private func addDocuments(_ urls: [URL]) {
        guard let id = tender?.id, !urls.isEmpty else { return }
        let docs = urls.map {
            TenderDocument(name: $0.lastPathComponent, type: "Specification",
                           pages: 8 + abs($0.lastPathComponent.hashValue % 80),
                           version: "1.0", imported: .now, state: .imported, sampleResource: nil)
        }
        workspace.update(id) {
            $0.documents.append(contentsOf: docs)
            if $0.status == .draft { $0.status = .imported }
        }
    }
}
