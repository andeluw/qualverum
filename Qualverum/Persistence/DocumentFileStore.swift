//
//  DocumentFileStore.swift
//  Qualverum
//
//  Created by Andrew Wallace on 05/09/26.
//

import Foundation

struct DocumentFileStore {
    private let directoryURL: URL

    init(
        directoryURL: URL = AppDirectories.documents
    ) {
        self.directoryURL = directoryURL
    }

    func importPDF(
        from sourceURL: URL,
        documentID: UUID
    ) throws -> String {
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )

        let hasAccess =
            sourceURL.startAccessingSecurityScopedResource()

        defer {
            if hasAccess {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        let storedFilename =
            "\(documentID.uuidString).pdf"

        let destinationURL =
            directoryURL.appending(
                path: storedFilename
            )

        if FileManager.default.fileExists(
            atPath: destinationURL.path
        ) {
            try FileManager.default.removeItem(
                at: destinationURL
            )
        }

        try FileManager.default.copyItem(
            at: sourceURL,
            to: destinationURL
        )

        return storedFilename
    }

    func url(
        for storedFilename: String
    ) -> URL {
        directoryURL.appending(
            path: storedFilename
        )
    }

    func delete(
        storedFilename: String
    ) throws {
        let fileURL = url(
            for: storedFilename
        )

        guard
            FileManager.default.fileExists(
                atPath: fileURL.path
            )
        else {
            return
        }

        try FileManager.default.removeItem(
            at: fileURL
        )
    }
}
