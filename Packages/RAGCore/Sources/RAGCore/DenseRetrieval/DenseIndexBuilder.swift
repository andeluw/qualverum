//
//  DenseIndexBuilder.swift
//  RAGCore
//
//  Created by Andrew Wallace on 03/09/26.
//

import Foundation

public struct DenseIndexBuilder: Sendable {
    private let embeddingProvider: any EmbeddingProvider

    public init(
        embeddingProvider: any EmbeddingProvider
    ) {
        self.embeddingProvider = embeddingProvider
    }

    public func build(
        from chunks: [DocumentChunk]
    ) async throws -> [DenseIndexEntry] {
        var entries: [DenseIndexEntry] = []
        entries.reserveCapacity(chunks.count)

        for chunk in chunks {
            try Task.checkCancellation()

            guard !chunk.text
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .isEmpty
            else {
                throw DenseRetrievalError.emptyChunkText(
                    chunkID: chunk.id
                )
            }

            let values =
                try await embeddingProvider
                    .embedDocument(chunk.text)

            let vector = try EmbeddingVector(
                values: values
            )

            let entry = try DenseIndexEntry(
                chunk: chunk,
                vector: vector
            )

            entries.append(entry)
        }

        return entries
    }
}
