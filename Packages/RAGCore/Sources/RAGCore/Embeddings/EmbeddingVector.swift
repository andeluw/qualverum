//
//  EmbeddingVector.swift
//  RAGCore
//
//  Created by Andrew Wallace on 03/09/26.
//

public enum EmbeddingVectorError:
    Error,
    Sendable,
    Equatable
{
    case empty
    case nonFinite
    case zeroNorm
}

public struct EmbeddingVector: Sendable {
    public let values: [Float]

    public var dimension: Int {
        values.count
    }

    public init(
        values: [Float]
    ) throws {
        guard !values.isEmpty else {
            throw EmbeddingVectorError.empty
        }

        guard values.allSatisfy(\.isFinite) else {
            throw EmbeddingVectorError.nonFinite
        }

        self.values = values
    }

    public func normalized() throws -> EmbeddingVector {
        let squaredSum = values.reduce(Float.zero) {
            $0 + ($1 * $1)
        }

        let norm = squaredSum.squareRoot()

        guard norm.isFinite else {
            throw EmbeddingVectorError.nonFinite
        }

        guard norm > 0 else {
            throw EmbeddingVectorError.zeroNorm
        }

        return try EmbeddingVector(
            values: values.map { $0 / norm }
        )
    }
}
