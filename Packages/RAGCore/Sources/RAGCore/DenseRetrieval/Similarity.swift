//
//  Similarity.swift
//  RAGCore
//
//  Created by Andrew Wallace on 03/09/26.
//

import Accelerate

enum Similarity {
    static func dotProduct(
        _ lhs: EmbeddingVector,
        _ rhs: EmbeddingVector
    ) throws -> Float {
        guard lhs.dimension == rhs.dimension else {
            throw DenseRetrievalError.dimensionMismatch(
                expected: lhs.dimension,
                actual: rhs.dimension
            )
        }

        return vDSP.dot(
            lhs.values,
            rhs.values
        )
    }
}
