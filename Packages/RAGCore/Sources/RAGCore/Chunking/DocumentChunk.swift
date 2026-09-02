//
//  DocumentChunk.swift
//  RAGCore
//
//  Created by Andrew Wallace on 02/09/26.
//

public enum DocumentChunkKind: Sendable {
    case parent
    case child
}

public struct DocumentChunk: Sendable {
    public let id: String
    public let documentID: String
    public let text: String
    public let pageNumber: Int
    public let sectionPath: [String]
    public let parentID: String?
    public let kind: DocumentChunkKind

    public init(
        id: String,
        documentID: String,
        text: String,
        pageNumber: Int,
        sectionPath: [String] = [],
        parentID: String? = nil,
        kind: DocumentChunkKind = .child
    ) {
        self.id = id
        self.documentID = documentID
        self.text = text
        self.pageNumber = pageNumber
        self.sectionPath = sectionPath
        self.parentID = parentID
        self.kind = kind
    }
}
