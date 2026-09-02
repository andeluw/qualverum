//
//  ParsedDocument.swift
//  RAGCore
//
//  Created by Andrew Wallace on 02/09/26.
//

public struct ParsedDocument: Sendable {
    public let id: String
    public let title: String
    public let pages: [ParsedPage]

    public init(id: String, title: String, pages: [ParsedPage]) {
        self.id = id
        self.title = title
        self.pages = pages
    }
}
