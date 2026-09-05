//
//  VecturaManifestStore.swift
//  RAGCore
//
//  Created by Andrew Wallace on 05/09/26.
//

import Foundation

actor VecturaManifestStore {
    private let directoryURL: URL

    init(directoryURL: URL) {
        self.directoryURL = directoryURL
    }

    func load(
        namespaceID: String
    ) throws -> VecturaManifest {
        let url = manifestURL(
            namespaceID: namespaceID
        )

        guard
            FileManager.default.fileExists(atPath: url.path)
        else {
            return VecturaManifest()
        }

        let data = try Data(
            contentsOf: url
        )

        return try JSONDecoder().decode(
            VecturaManifest.self,
            from: data
        )
    }

    func save(
        _ manifest: VecturaManifest,
        namespaceID: String
    ) throws {
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )

        let data = try JSONEncoder().encode(
            manifest
        )

        try data.write(
            to: manifestURL(namespaceID: namespaceID),
            options: .atomic
        )
    }

    func delete(
        namespaceID: String
    ) throws {
        let url = manifestURL(namespaceID: namespaceID)

        guard FileManager.default.fileExists(atPath: url.path)
        else {
            return
        }

        try FileManager.default.removeItem(at: url)
    }

    private func manifestURL(
        namespaceID: String
    ) -> URL {
        directoryURL.appending(
            path: "\(namespaceID).json"
        )
    }
}
