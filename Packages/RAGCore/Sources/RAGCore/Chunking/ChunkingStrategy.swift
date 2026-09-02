//
//  ChunkingStrategy.swift
//  RAGCore
//
//  Created by Andrew Wallace on 02/09/26.
//

public protocol ChunkingStrategy: Sendable {
    func chunk(_ document: ParsedDocument) -> [DocumentChunk]
}
