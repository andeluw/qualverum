//
//  DocumentBounds.swift
//  RAGCore
//
//  Created by Andrew Wallace on 03/09/26.
//

public struct DocumentBounds: Sendable {
    public let minX: Double
    public let minY: Double
    public let maxX: Double
    public let maxY: Double

    public init(
        minX: Double,
        minY: Double,
        maxX: Double,
        maxY: Double
    ) {
        self.minX = minX
        self.minY = minY
        self.maxX = maxX
        self.maxY = maxY
    }
}
