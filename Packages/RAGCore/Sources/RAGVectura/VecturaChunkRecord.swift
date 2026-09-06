//
//  VecturaChunkRecord.swift
//  RAGCore
//
//  Created by Andrew Wallace on 05/09/26.
//

import Foundation
import RAGCore

struct VecturaChunkRecord: Codable, Sendable {
    let vecturaID: UUID?

    let ownerDocumentID: String

    let chunkID: String
    let documentID: String
    let text: String
    let pageNumber: Int
    let sectionPath: [String]
    let parentID: String?
    let kind: String

    init(
        vecturaID: UUID?,
        ownerDocumentID: String,
        chunk: DocumentChunk
    ) {
        self.vecturaID = vecturaID
        self.ownerDocumentID = ownerDocumentID

        chunkID = chunk.id
        documentID = chunk.documentID
        text = chunk.text
        pageNumber = chunk.pageNumber
        sectionPath = chunk.sectionPath
        parentID = chunk.parentID

        switch chunk.kind {
        case .parent:
            kind = "parent"
        case .child:
            kind = "child"
        }
    }

    func makeChunk() -> DocumentChunk {
        DocumentChunk(
            id: chunkID,
            documentID: documentID,
            text: text,
            pageNumber: pageNumber,
            sectionPath: sectionPath,
            parentID: parentID,
            kind: kind == "parent" ? .parent : .child
        )
    }
}
