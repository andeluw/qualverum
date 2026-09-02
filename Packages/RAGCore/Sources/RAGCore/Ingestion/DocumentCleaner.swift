//
//  DocumentCleaner.swift
//  RAGCore
//
//  Created by Andrew Wallace on 03/09/26.
//

import Foundation

struct DocumentCleaner: Sendable {
    private let edgeThreshold = 0.10
    private let repetitionRatio = 0.50
    private let minimumRepeats = 2

    func clean(
        _ document: ParsedDocument
    ) -> ParsedDocument {
        guard document.pages.count >= minimumRepeats else {
            return document
        }

        var pagesByCandidate:
            [CandidateKey: Set<Int>] = [:]

        for page in document.pages {
            for block in page.blocks {
                guard
                    let key = candidateKey(
                        for: block
                    )
                else {
                    continue
                }

                pagesByCandidate[
                    key,
                    default: []
                ]
                .insert(page.number)
            }
        }

        let requiredRepeats = max(
            minimumRepeats,
            Int(
                ceil(
                    Double(document.pages.count)
                        * repetitionRatio
                )
            )
        )

        let repeatedKeys = Set(
            pagesByCandidate
                .filter {
                    $0.value.count
                        >= requiredRepeats
                }
                .map(\.key)
        )

        guard !repeatedKeys.isEmpty else {
            return document
        }

        let cleanedPages = document.pages.map { page in
            let blocks = page.blocks.filter { block in
                guard
                    let key = candidateKey(
                        for: block
                    )
                else {
                    return true
                }

                return !repeatedKeys.contains(
                    key
                )
            }

            return ParsedPage(
                number: page.number,
                rawText: page.rawText,
                blocks: blocks
            )
        }

        return ParsedDocument(
            id: document.id,
            title: document.title,
            pages: cleanedPages
        )
    }

    private func candidateKey(
        for block: DocumentBlock
    ) -> CandidateKey? {
        guard let bounds = block.bounds else {
            return nil
        }

        let edge: PageEdge

        if bounds.maxY >= 1 - edgeThreshold {
            edge = .top
        } else if bounds.minY <= edgeThreshold {
            edge = .bottom
        } else {
            return nil
        }

        let fingerprint = fingerprint(
            block.text
        )

        guard !fingerprint.isEmpty else {
            return nil
        }

        return CandidateKey(
            edge: edge,
            fingerprint: fingerprint
        )
    }

    private func fingerprint(
        _ text: String
    ) -> String {
        let normalized = text
            .lowercased()
            .replacingOccurrences(
                of: #"\d+"#,
                with: "#",
                options: .regularExpression
            )
            .split(
                whereSeparator: \.isWhitespace
            )
            .joined(separator: " ")

        let compact = normalized.filter {
            !$0.isWhitespace
        }

        if isPageNumberLike(
            compact
        ) {
            return "<page-number>"
        }

        return normalized
    }

    private func isPageNumberLike(
        _ text: String
    ) -> Bool {
        text.range(
            of:
                #"^(?:#(?:[-|/.]?(?:p|page))?|(?:p|page)[-|/.]?#)$"#,
            options: .regularExpression
        ) != nil
    }
}

private enum PageEdge: Hashable {
    case top
    case bottom
}

private struct CandidateKey: Hashable {
    let edge: PageEdge
    let fingerprint: String
}
