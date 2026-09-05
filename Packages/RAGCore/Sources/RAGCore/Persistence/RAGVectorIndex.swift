//
//  RAGVectorIndex.swift
//  RAGCore
//
//  Created by Andrew Wallace on 05/09/26.
//

public protocol RAGVectorIndex: Sendable {
    func replaceDocument(
        namespaceID: String,
        documentID: String,
        chunks: [DocumentChunk]
    ) async throws
    
    func retrieve(
        namespaceID: String,
        query: EmbeddingVector,
        topK: Int
    ) async throws -> [RetrievalResult]
    
    func removeDocument(
        namespaceID: String,
        documentID: String
    ) async throws
    
    func hasDocuments(
        namespaceID: String
    ) async throws -> Bool
}
