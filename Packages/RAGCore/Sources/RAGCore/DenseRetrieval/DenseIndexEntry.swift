//
//  DenseIndexEntry.swift
//  RAGCore
//
//  Created by Andrew Wallace on 03/09/26.
//

public struct DenseIndexEntry: Sendable {
    public let chunk: DocumentChunk
    public let vector: EmbeddingVector

    public init(
        chunk: DocumentChunk,
        vector: EmbeddingVector
    ) throws {
        self.chunk = chunk
        self.vector = try vector.normalized()
    }
}
