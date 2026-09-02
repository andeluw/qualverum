//
//  StructureAwareChunker.swift
//  RAGCore
//
//  Created by Andrew Wallace on 02/09/26.
//

import Foundation

public struct StructureAwareChunker: ChunkingStrategy {
    private let resolver: StructureHierarchyResolver
    private let splitter: ChunkSplitter

    public init(maxWords: Int = 180) {
        resolver = StructureHierarchyResolver()
        splitter = ChunkSplitter(maxWords: maxWords)
    }

    public func chunk(_ document: ParsedDocument) -> [DocumentChunk] {
        let resolved = resolver.resolve(document)

        var chunks: [DocumentChunk] = []
        var currentBlocks: [ResolvedBlock] = []
        var currentPath: [String] = []
        var unitIndex = 0

        func flushCurrentUnit() {
            guard !currentBlocks.isEmpty else {
                return
            }

            let body = bodyText(from: currentBlocks)

            guard !body.isEmpty else {
                currentBlocks = []
                return
            }

            unitIndex += 1

            appendTextChunks(
                documentID: document.id,
                body: body,
                pageNumber: currentBlocks[0].pageNumber,
                path: currentPath,
                unitIndex: unitIndex,
                to: &chunks
            )

            currentBlocks = []
        }

        for block in resolved.blocks {
            switch block.kind {
            case .heading:
                flushCurrentUnit()
                currentPath = block.sectionPath

            case .table:
                flushCurrentUnit()

                unitIndex += 1

                appendTableChunks(
                    documentID: document.id,
                    block: block,
                    unitIndex: unitIndex,
                    to: &chunks
                )

                currentPath = block.sectionPath

            case .paragraph, .listItem, .text:
                if currentBlocks.isEmpty {
                    currentPath = block.sectionPath
                }

                currentBlocks.append(block)
            }
        }

        flushCurrentUnit()

        return chunks
    }

    // MARK: - Text Chunks

    private func appendTextChunks(
        documentID: String,
        body: String,
        pageNumber: Int,
        path: [String],
        unitIndex: Int,
        to chunks: inout [DocumentChunk]
    ) {
        let parentID = "\(documentID)#parent-\(unitIndex)"

        chunks.append(
            DocumentChunk(
                id: parentID,
                documentID: documentID,
                text: contextualizedText(
                    path: path,
                    body: body
                ),
                pageNumber: pageNumber,
                sectionPath: path,
                kind: .parent
            )
        )

        let pieces = splitter.split(body)

        for (index, piece) in pieces.enumerated() {
            chunks.append(
                DocumentChunk(
                    id: "\(documentID)#child-\(unitIndex)-\(index + 1)",
                    documentID: documentID,
                    text: contextualizedText(
                        path: path,
                        body: piece
                    ),
                    pageNumber: pageNumber,
                    sectionPath: path,
                    parentID: parentID,
                    kind: .child
                )
            )
        }
    }

    private func bodyText(
        from blocks: [ResolvedBlock]
    ) -> String {
        blocks
            .map(\.text)
            .map {
                $0.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            }
            .filter {
                !$0.isEmpty
            }
            .joined(separator: "\n\n")
    }

    // MARK: - Table Chunks

    private func appendTableChunks(
        documentID: String,
        block: ResolvedBlock,
        unitIndex: Int,
        to chunks: inout [DocumentChunk]
    ) {
        guard case .table(let table) = block.content else {
            return
        }

        let parentID = "\(documentID)#parent-\(unitIndex)"

        chunks.append(
            DocumentChunk(
                id: parentID,
                documentID: documentID,
                text: contextualizedText(
                    path: block.sectionPath,
                    body: table.text
                ),
                pageNumber: block.pageNumber,
                sectionPath: block.sectionPath,
                kind: .parent
            )
        )

        for (index, row) in table.rows.enumerated() {
            let rowText =
                row
                .map(\.text)
                .map {
                    $0.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                }
                .filter {
                    !$0.isEmpty
                }
                .joined(separator: "\t")

            guard !rowText.isEmpty else {
                continue
            }

            chunks.append(
                DocumentChunk(
                    id: "\(documentID)#child-\(unitIndex)-\(index + 1)",
                    documentID: documentID,
                    text: contextualizedText(
                        path: block.sectionPath,
                        body: rowText
                    ),
                    pageNumber: block.pageNumber,
                    sectionPath: block.sectionPath,
                    parentID: parentID,
                    kind: .child
                )
            )
        }
    }

    // MARK: - Context

    private func contextualizedText(
        path: [String],
        body: String
    ) -> String {
        guard !path.isEmpty else {
            return body
        }

        return """
            \(path.joined(separator: " > "))

            \(body)
            """
    }
}
