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
    @State private var deleting = false
    @State private var pendingDeletion: TenderDocument?

    private let documentImporter = DocumentImportService()
    private let fileStore = DocumentFileStore()

    private var isBusy: Bool { indexing || deleting }

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
                        Divider()
                        Button("Delete", role: .destructive) {
                            pendingDeletion = document
                        }
                        .disabled(isBusy)
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
                    if isBusy {
                        ProgressView().controlSize(.small)
                    }
                }

                ToolbarItem {
                    Button {
                        importing = true
                    } label: {
                        Label("Add Documents", systemImage: "plus")
                    }
                    .disabled(isBusy)
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
        .confirmationDialog(
            "Delete this document?",
            isPresented: Binding(
                get: { pendingDeletion != nil },
                set: { if !$0 { pendingDeletion = nil } }
            ),
            presenting: pendingDeletion
        ) { document in
            Button("Delete", role: .destructive) { delete(document) }
            Button("Cancel", role: .cancel) { pendingDeletion = nil }
        } message: { document in
            Text("\(document.name) will be removed from this tender. This cannot be undone.")
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

    // Clear the document's vectors and stored PDF before dropping its metadata.
    // Best-effort: stale documents from before persistence have no stored file
    // or index entry, so those steps simply do nothing.
    private func delete(_ document: TenderDocument) {
        guard let tenderID = tender?.id else { return }

        pendingDeletion = nil
        deleting = true

        Task { @MainActor in
            defer { deleting = false }

            do {
                try await rag.removeDocument(
                    tenderID: tenderID,
                    documentID: document.id
                )
            } catch {
                print("Failed to remove \(document.name) from index:\n\(error)")
            }

            if let stored = document.storedFilename {
                do {
                    try fileStore.delete(storedFilename: stored)
                } catch {
                    print("Failed to delete file for \(document.name):\n\(error)")
                }
            }

            if app.selectedDocumentID == document.id {
                app.selectedDocumentID = nil
            }

            workspace.update(tenderID) { tender in
                tender.documents.removeAll { $0.id == document.id }
            }
        }
    }

    private func addDocuments(_ urls: [URL]) {
        guard let tenderID = tender?.id, !urls.isEmpty else {
            return
        }

        indexing = true

        Task { @MainActor in
            defer {
                indexing = false
            }

            await documentImporter.importAndIndex(
                urls: urls,
                tenderID: tenderID,
                workspace: workspace,
                rag: rag
            )
        }
    }
}
