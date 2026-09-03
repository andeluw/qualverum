//
//  ExactDenseRetriever.swift
//  RAGCore
//
//  Created by Andrew Wallace on 03/09/26.
//

public struct ExactDenseRetriever: DenseRetriever {
    private let entries: [DenseIndexEntry]
    private let dimension: Int?

    public init(
        entries: [DenseIndexEntry]
    ) throws {
        let expectedDimension =
            entries.first?.vector.dimension

        if let expectedDimension {
            for entry in entries.dropFirst() {
                guard
                    entry.vector.dimension
                        == expectedDimension
                else {
                    throw DenseRetrievalError
                        .dimensionMismatch(
                            expected: expectedDimension,
                            actual: entry.vector.dimension
                        )
                }
            }
        }

        self.entries = entries
        self.dimension = expectedDimension
    }

    public func retrieve(
        query: EmbeddingVector,
        topK: Int
    ) async throws -> [RetrievalResult] {
        guard topK > 0 else {
            throw DenseRetrievalError.invalidTopK(
                topK
            )
        }

        guard let dimension else {
            return []
        }

        guard query.dimension == dimension else {
            throw DenseRetrievalError
                .dimensionMismatch(
                    expected: dimension,
                    actual: query.dimension
                )
        }

        let normalizedQuery =
            try query.normalized()

        var results: [RetrievalResult] = []
        results.reserveCapacity(entries.count)

        for (index, entry) in entries.enumerated() {
            if index.isMultiple(of: 256) {
                try Task.checkCancellation()
            }

            let score =
                try Similarity.dotProduct(
                    normalizedQuery,
                    entry.vector
                )

            results.append(
                RetrievalResult(
                    chunk: entry.chunk,
                    score: score
                )
            )
        }

        results.sort { lhs, rhs in
            if lhs.score == rhs.score {
                return lhs.chunk.id
                    < rhs.chunk.id
            }

            return lhs.score > rhs.score
        }

        if topK >= results.count {
            return results
        }

        return Array(
            results.prefix(topK)
        )
    }
}
