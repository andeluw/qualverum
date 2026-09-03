//
//  RetrievalResult.swift
//  RAGCore
//
//  Created by Andrew Wallace on 03/09/26.
//

public struct RetrievalResult: Sendable {
    public let chunk: DocumentChunk
    public let score: Float

    public init(
        chunk: DocumentChunk,
        score: Float
    ) {
        self.chunk = chunk
        self.score = score
    }
}
