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
    @Environment(RAGService.self) private var rag

    @State private var sortOrder = [
        KeyPathComparator(\TenderDocument.imported, order: .reverse)
    ]
    @State private var importing = false
    @State private var indexing = false

    private let fileStore = DocumentFileStore()

    private var tender: Tender? {
        workspace.store.tender(app.activeTenderID)
    }

    private var rows: [TenderDocument] {
        (tender?.documents ?? []).sorted(using: sortOrder)
    }

    var body: some View {
        @Bindable var app = app

        return Group {
            if tender == nil {
                ContentUnavailableView(
                    "No Tender Selected",
                    systemImage: "doc.on.doc",
                    description: Text("Choose a tender to see its documents.")
                )

            } else if rows.isEmpty {
                ContentUnavailableView {
                    Label("No Documents", systemImage: "doc.on.doc")
                } description: {
                    Text("Documents you add to this tender appear here.")
                } actions: {
                    Button("Add Documents…") { importing = true }
                        .disabled(indexing)
                }

            } else {
                Table(
                    rows,
                    selection: $app.selectedDocumentID,
                    sortOrder: $sortOrder
                ) {
                    TableColumn("Name", value: \.name) {
                        Text($0.name).fontWeight(.medium)
                    }
                    TableColumn("Type", value: \.type)
                    TableColumn("Pages", value: \.pages) { Text("\($0.pages)") }
                    TableColumn("Version", value: \.version)
                    TableColumn("Imported", value: \.imported) {
                        Text($0.imported.short)
                    }
                    TableColumn("State", value: \.state.rawValue) {
                        Text($0.state.rawValue)
                    }
                }
                .contextMenu(forSelectionType: TenderDocument.ID.self) { ids in
                    if let id = ids.first,
                        let document = rows.first(where: { $0.id == id })
                    {
                        Button("Open") { open(document) }
                    }
                } primaryAction: { ids in
                    if let id = ids.first,
                        let document = rows.first(where: { $0.id == id })
                    {
                        open(document)
                    }
                }
            }
        }
        .navigationTitle("Tender Documents")
        .toolbar {
            if tender != nil {
                ToolbarItem {
                    if indexing {
                        ProgressView().controlSize(.small)
                    }
                }

                ToolbarItem {
                    Button {
                        importing = true
                    } label: {
                        Label("Add Documents", systemImage: "plus")
                    }
                    .disabled(indexing)
                }
            }
        }
        .fileImporter(
            isPresented: $importing,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: true
        ) { result in
            if case .success(let urls) = result {
                addDocuments(urls)
            }
        }
    }

    private func open(_ document: TenderDocument) {
        app.pendingDocument = PDFRequest(
            title: document.name,
            resource: document.sampleResource,
            storedFilename: document.storedFilename,
            page: 1
        )
    }

    private func addDocuments(_ urls: [URL]) {
        guard let tenderID = tender?.id, !urls.isEmpty else { return }

        var imports:
            [(
                document: TenderDocument,
                url: URL
            )] = []

        for sourceURL in urls {
            let documentID = UUID()

            do {
                let storedFilename =
                    try fileStore.importPDF(
                        from: sourceURL,
                        documentID: documentID
                    )

                let document = TenderDocument(
                    id: documentID,
                    name: sourceURL.lastPathComponent,
                    type: "Specification",
                    pages: 0,
                    version: "1.0",
                    imported: .now,
                    state: .imported,
                    sampleResource: nil,
                    storedFilename: storedFilename
                )

                let storedURL = fileStore.url(
                    for: storedFilename
                )

                imports.append(
                    (
                        document: document,
                        url: storedURL
                    )
                )

            } catch {
                print(
                    "Failed to import \(sourceURL.lastPathComponent): \(error)"
                )
            }
        }

        guard !imports.isEmpty else {
            return
        }

        workspace.update(tenderID) { tender in
            tender.documents.append(
                contentsOf: imports.map(\.document)
            )

            if tender.status == .draft {
                tender.status = .imported
            }
        }

        indexing = true

        Task { @MainActor in
            defer { indexing = false }

            // Sequential on purpose: one model instance and
            // predictable indexing pressure.
            for (document, url) in imports {
                do {
                    let summary = try await rag.indexDocument(
                        tenderID: tenderID,
                        documentID: document.id,
                        url: url
                    )

                    workspace.update(tenderID) { tender in
                        guard
                            let index = tender.documents.firstIndex(
                                where: { $0.id == document.id }
                            )
                        else { return }

                        tender.documents[index].pages = summary.pageCount
                        tender.documents[index].state = .indexed
                    }

                } catch {
                    workspace.update(tenderID) { tender in
                        guard
                            let index = tender.documents.firstIndex(
                                where: { $0.id == document.id }
                            )
                        else { return }

                        tender.documents[index].state = .unavailable
                    }

                    print("Failed to index \(document.name):\n\(error)")
                }
            }
        }
    }
}
