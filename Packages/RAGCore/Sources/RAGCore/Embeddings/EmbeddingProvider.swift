//
//  EmbeddingProvider.swift
//  RAGCore
//
//  Created by Andrew Wallace on 03/09/26.
//

public protocol EmbeddingProvider: Sendable {
    var dimension: Int { get }
    
    func embedQuery(
        _ text: String
    ) async throws -> [Float]

    func embedDocument(
        _ text: String
    ) async throws -> [Float]
}
