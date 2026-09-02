//
//  ParsedPage.swift
//  RAGCore
//
//  Created by Andrew Wallace on 02/09/26.
//

public struct ParsedPage: Sendable {
    public let number: Int
    public let rawText: String
    public let blocks: [DocumentBlock]

    public init(number: Int, rawText: String, blocks: [DocumentBlock]) {
        self.number = number
        self.rawText = rawText
        self.blocks = blocks
    }
}
