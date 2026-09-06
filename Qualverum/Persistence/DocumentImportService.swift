//
//  DocumentImportService.swift
//  Qualverum
//
//  Created by Andrew Wallace on 06/09/26.
//

import Foundation

struct DocumentImportService {
    private let fileStore: DocumentFileStore

    init(
        fileStore: DocumentFileStore = DocumentFileStore()
    ) {
        self.fileStore = fileStore
    }

    @MainActor
    func importAndIndex(
        urls: [URL],
        tenderID: UUID,
        workspace: WorkspaceService,
        rag: RAGService
    ) async {
        var imports: [(
            document: TenderDocument,
            url: URL
        )] = []

        for sourceURL in urls {
            let documentID = UUID()

            do {
                let storedFilename = try fileStore.importPDF(
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

                imports.append(
                    (
                        document: document,
                        url: fileStore.url(
                            for: storedFilename
                        )
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
                contentsOf: imports.map { $0.document }
            )

            if tender.status == .draft {
                tender.status = .imported
            }

            if !tender.versions.isEmpty {
                tender.versions[0].documentCount = tender.documents.count
            }
        }

        for item in imports {
            do {
                let summary = try await rag.indexDocument(
                    tenderID: tenderID,
                    documentID: item.document.id,
                    url: item.url
                )

                workspace.update(tenderID) { tender in
                    guard
                        let index = tender.documents.firstIndex(
                            where: { $0.id == item.document.id }
                        )
                    else {
                        return
                    }

                    tender.documents[index].pages = summary.pageCount
                    tender.documents[index].state = .indexed
                }
            } catch {
                workspace.update(tenderID) { tender in
                    guard
                        let index = tender.documents.firstIndex(
                            where: { $0.id == item.document.id }
                        )
                    else {
                        return
                    }

                    tender.documents[index].state = .unavailable
                }

                print(
                    "Failed to index \(item.document.name):\n\(error)"
                )
            }
        }
    }
}
