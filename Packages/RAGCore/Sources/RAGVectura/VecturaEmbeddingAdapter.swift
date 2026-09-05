//
//  RAGVecturaEmbeddingAdapter.swift
//  RAGCore
//
//  Created by Andrew Wallace on 05/09/26.
//

import RAGCore
import VecturaKit

struct VecturaEmbeddingAdapter: VecturaEmbedder {
    let provider: any EmbeddingProvider

    var dimension: Int {
        get async throws {
            provider.dimension
        }
    }

    func embed(
        texts: [String]
    ) async throws -> [[Float]] {
        var result: [[Float]] = []
        result.reserveCapacity(texts.count)

        for text in texts {
            result.append(
                try await provider.embedDocument(text)
            )
        }

        return result
    }

    func embed(text: String) async throws -> [Float] {
        try await provider.embedQuery(text)
    }
}
