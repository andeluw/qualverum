//
//  DenseRetrievalError.swift
//  RAGCore
//
//  Created by Andrew Wallace on 03/09/26.
//


public enum DenseRetrievalError: Error, Sendable, Equatable {
    case invalidTopK(Int)

    case dimensionMismatch(
        expected: Int,
        actual: Int
    )

    case emptyChunkText(
        chunkID: String
    )
}
