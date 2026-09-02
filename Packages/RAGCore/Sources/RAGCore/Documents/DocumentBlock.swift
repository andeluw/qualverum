//
//  DocumentBlock.swift
//  RAGCore
//
//  Created by Andrew Wallace on 02/09/26.
//

public struct DocumentBlock: Sendable {
    public let pageNumber: Int
    public let content: DocumentBlockContent
    public let bounds: DocumentBounds? // Vision

    public init(
        pageNumber: Int,
        content: DocumentBlockContent,
        bounds: DocumentBounds? = nil
    ) {
        self.pageNumber = pageNumber
        self.content = content
        self.bounds = bounds
    }

    public var text: String {
        content.text
    }
}

public enum DocumentBlockContent: Sendable {
    case title(String)
    case paragraph(String)
    case listItem(marker: String?, text: String)
    case table(DocumentTable)
    case text(String)

    public var text: String {
        switch self {
        case .title(let text):
            text

        case .paragraph(let text):
            text

        case .listItem(let marker, let text):
            if let marker {
                "\(marker) \(text)"
            } else {
                text
            }

        case .table(let table):
            table.text

        case .text(let text):
            text
        }
    }
}
