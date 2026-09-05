//
//  VecturaRAGIndex.swift
//  RAGCore
//
//  Created by Andrew Wallace on 05/09/26.
//

import Foundation
import RAGCore
import VecturaKit

public actor VecturaRAGIndex: RAGVectorIndex {
    private let embeddingProvider: any EmbeddingProvider
    private let rootDirectory: URL
    private let manifestStore: VecturaManifestStore

    private var databases: [String: VecturaKit] = [:]

    public init(
        rootDirectory: URL,
        embeddingProvider: any EmbeddingProvider
    ) {
        self.rootDirectory = rootDirectory
        self.embeddingProvider = embeddingProvider

        self.manifestStore = VecturaManifestStore(
            directoryURL: rootDirectory.appending(
                path: "Manifests",
                directoryHint: .isDirectory
            )
        )
    }

    // MARK: - Indexing

    public func replaceDocument(
        namespaceID: String,
        documentID: String,
        chunks: [DocumentChunk]
    ) async throws {
        let database = try await database(
            for: namespaceID
        )

        var manifest = try await manifestStore.load(
            namespaceID: namespaceID
        )

        let previousRecords = manifest.chunks.filter {
            $0.ownerDocumentID == documentID
        }

        let previousIDs = previousRecords.compactMap(
            \.vecturaID
        )

        if !previousIDs.isEmpty {
            try await database.deleteDocuments(
                ids: previousIDs
            )
        }

        manifest.chunks.removeAll {
            $0.ownerDocumentID == documentID
        }

        let children = chunks.filter {
            $0.kind == .child
        }

        let vecturaIDs = children.map { _ in
            UUID()
        }

        if !children.isEmpty {
            _ = try await database.addDocuments(
                texts: children.map(\.text),
                ids: vecturaIDs
            )
        }

        var idsByChunk: [String: UUID] = [:]

        for (chunk, vecturaID) in zip(
            children,
            vecturaIDs
        ) {
            idsByChunk[chunk.id] = vecturaID
        }

        let records = chunks.map { chunk in
            VecturaChunkRecord(
                vecturaID: idsByChunk[chunk.id],
                ownerDocumentID: documentID,
                chunk: chunk
            )
        }

        manifest.chunks.append(
            contentsOf: records
        )

        try await manifestStore.save(
            manifest,
            namespaceID: namespaceID
        )
    }

    public func retrieve(namespaceID: String, query: EmbeddingVector, topK: Int)
        async throws -> [RetrievalResult]
    {
        let database = try await database(
            for: namespaceID
        )

        let manifest = try await manifestStore.load(
            namespaceID: namespaceID
        )

        var recordsByID: [UUID: VecturaChunkRecord] = [:]

        for record in manifest.chunks {
            guard let vecturaID = record.vecturaID else {
                continue
            }

            recordsByID[vecturaID] = record
        }

        let results = try await database.search(
            query: .vector(query.values),
            numResults: topK,
            threshold: nil
        )

        return results.compactMap { result in
            guard let record = recordsByID[result.id] else {
                return nil
            }

            return RetrievalResult(
                chunk: record.makeChunk(),
                score: result.score
            )
        }
    }

    public func removeDocument(namespaceID: String, documentID: String)
        async throws
    {
        let database = try await database(
            for: namespaceID
        )

        var manifest = try await manifestStore.load(
            namespaceID: namespaceID
        )

        let vecturaIDs = manifest.chunks
            .filter {
                $0.ownerDocumentID == documentID
            }
            .compactMap(
                \.vecturaID
            )

        if !vecturaIDs.isEmpty {
            try await database.deleteDocuments(
                ids: vecturaIDs
            )
        }

        manifest.chunks.removeAll {
            $0.ownerDocumentID == documentID
        }

        try await manifestStore.save(
            manifest,
            namespaceID: namespaceID
        )
    }

    public func hasDocuments(namespaceID: String) async throws -> Bool {
        let database = try await database(
            for: namespaceID
        )

        return try await database.documentCount > 0
    }

    private func database(
        for namespaceID: String
    ) async throws -> VecturaKit {
        if let database = databases[namespaceID] {
            return database
        }

        let embedder = VecturaEmbeddingAdapter(
            provider: embeddingProvider
        )

        let config = try VecturaConfig(
            name: namespaceID,
            directoryURL: rootDirectory.appending(
                path: "Vectura",
                directoryHint: .isDirectory
            ),
            dimension: embeddingProvider.dimension
        )

        let searchEngine = VectorSearchEngine(
            embedder: embedder
        )

        let database = try await VecturaKit(
            config: config,
            embedder: embedder,
            searchEngine: searchEngine
        )

        databases[namespaceID] = database

        return database
    }
}
