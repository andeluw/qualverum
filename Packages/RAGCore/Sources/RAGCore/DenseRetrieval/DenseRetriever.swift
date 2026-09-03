//
//  DenseRetriever.swift
//  RAGCore
//
//  Created by Andrew Wallace on 03/09/26.
//

public protocol DenseRetriever: Sendable {
    func retrieve(
        query: EmbeddingVector,
        topK: Int
    ) async throws -> [RetrievalResult]
}
