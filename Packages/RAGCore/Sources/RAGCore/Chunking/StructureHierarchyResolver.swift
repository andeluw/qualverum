//
//  StructureHierarchyResolver.swift
//  RAGCore
//
//  Created by Andrew Wallace on 03/09/26.
//

import Foundation

public struct ResolvedDocument: Sendable {
    public let id: String
    public let title: String
    public let blocks: [ResolvedBlock]

    public init(
        id: String,
        title: String,
        blocks: [ResolvedBlock]
    ) {
        self.id = id
        self.title = title
        self.blocks = blocks
    }
}

public struct ResolvedBlock: Sendable {
    public let pageNumber: Int
    public let sectionPath: [String]
    public let kind: ResolvedBlockKind
    public let content: DocumentBlockContent
    public let bounds: DocumentBounds?

    public init(
        pageNumber: Int,
        sectionPath: [String],
        kind: ResolvedBlockKind,
        content: DocumentBlockContent,
        bounds: DocumentBounds?
    ) {
        self.pageNumber = pageNumber
        self.sectionPath = sectionPath
        self.kind = kind
        self.content = content
        self.bounds = bounds
    }

    public var text: String {
        content.text
    }
}

public enum ResolvedBlockKind: Sendable {
    case heading(level: Int)
    case paragraph
    case listItem
    case table
    case text
}

public struct StructureHierarchyResolver: Sendable {
    public init() {}

    public func resolve(
        _ document: ParsedDocument
    ) -> ResolvedDocument {
        var resolved: [ResolvedBlock] = []
        var sectionPath: [String] = []

        for page in document.pages {
            let blocks = normalizedBlocks(
                for: page
            )

            for block in blocks {
                let text = block.text
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

                guard !text.isEmpty else {
                    continue
                }

                if let listItem = normalizedListItem(
                    from: block.content
                ) {
                    resolved.append(
                        ResolvedBlock(
                            pageNumber: block.pageNumber,
                            sectionPath: sectionPath,
                            kind: .listItem,
                            content: listItem,
                            bounds: block.bounds
                        )
                    )

                    continue
                }

                if let heading = detectHeading(
                    text,
                    currentDepth: sectionPath.count
                ) {
                    sectionPath = updatedPath(
                        sectionPath,
                        heading: heading
                    )

                    resolved.append(
                        ResolvedBlock(
                            pageNumber: block.pageNumber,
                            sectionPath: sectionPath,
                            kind: .heading(
                                level: heading.level
                            ),
                            content: block.content,
                            bounds: block.bounds
                        )
                    )

                    continue
                }

                resolved.append(
                    ResolvedBlock(
                        pageNumber: block.pageNumber,
                        sectionPath: sectionPath,
                        kind: resolvedKind(
                            for: block.content
                        ),
                        content: block.content,
                        bounds: block.bounds
                    )
                )
            }
        }

        return ResolvedDocument(
            id: document.id,
            title: document.title,
            blocks: resolved
        )
    }

    // MARK: - Normalization

    private func normalizedBlocks(
        for page: ParsedPage
    ) -> [DocumentBlock] {
        if !page.blocks.isEmpty {
            return removingBlocksInsideTables(
                deduplicated(page.blocks)
            )
        }

        return page.rawText
            .components(
                separatedBy: .newlines
            )
            .map {
                $0.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            }
            .filter {
                !$0.isEmpty
            }
            .map {
                DocumentBlock(
                    pageNumber: page.number,
                    content: .paragraph($0)
                )
            }
    }

    private func removingBlocksInsideTables(
        _ blocks: [DocumentBlock]
    ) -> [DocumentBlock] {
        let tableBounds = blocks.compactMap {
            block -> DocumentBounds? in

            guard case .table = block.content else {
                return nil
            }

            return block.bounds
        }

        guard !tableBounds.isEmpty else {
            return blocks
        }

        return blocks.filter { block in
            if case .table = block.content {
                return true
            }

            guard let bounds = block.bounds else {
                return true
            }

            let centerX =
                (bounds.minX + bounds.maxX) / 2

            let centerY =
                (bounds.minY + bounds.maxY) / 2

            let isInsideTable = tableBounds.contains {
                table in

                centerX >= table.minX
                    && centerX <= table.maxX
                    && centerY >= table.minY
                    && centerY <= table.maxY
            }

            return !isInsideTable
        }
    }

    private func deduplicated(
        _ blocks: [DocumentBlock]
    ) -> [DocumentBlock] {
        var result: [DocumentBlock] = []

        for block in blocks {
            if let index = result.firstIndex(
                where: {
                    isDuplicate(
                        $0,
                        block
                    )
                }
            ) {
                if priority(of: block.content)
                    > priority(
                        of: result[index].content
                    )
                {
                    result[index] = block
                }

                continue
            }

            result.append(block)
        }

        return result
    }

    private func isDuplicate(
        _ lhs: DocumentBlock,
        _ rhs: DocumentBlock
    ) -> Bool {
        guard
            normalizedText(lhs.text)
                == normalizedText(rhs.text)
        else {
            return false
        }

        return sameBounds(
            lhs.bounds,
            rhs.bounds
        )
    }

    private func normalizedText(
        _ text: String
    ) -> String {
        text
            .split(
                whereSeparator: \.isWhitespace
            )
            .joined(separator: " ")
            .lowercased()
    }

    private func sameBounds(
        _ lhs: DocumentBounds?,
        _ rhs: DocumentBounds?
    ) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return true

        case (.some(let lhs), .some(let rhs)):
            let tolerance = 0.005

            return
                abs(lhs.minX - rhs.minX) <= tolerance
                && abs(lhs.minY - rhs.minY) <= tolerance
                && abs(lhs.maxX - rhs.maxX) <= tolerance
                && abs(lhs.maxY - rhs.maxY) <= tolerance

        default:
            return false
        }
    }

    private func priority(
        of content: DocumentBlockContent
    ) -> Int {
        switch content {
        case .table:
            return 4

        case .listItem:
            return 3

        case .title:
            return 2

        case .paragraph:
            return 1

        case .text:
            return 0
        }
    }

    // MARK: - Headings

    private func detectHeading(
        _ text: String,
        currentDepth: Int
    ) -> Heading? {
        guard text.count <= 180 else {
            return nil
        }

        if isAnnexHeading(text) {
            return Heading(
                text: text,
                level: 1
            )
        }

        if isCriterionHeading(text) {
            return Heading(
                text: text,
                level: max(
                    currentDepth + 1,
                    1
                )
            )
        }

        if let level = numberedHeadingLevel(text),
           isLikelyNumberedHeading(text)
        {
            return Heading(
                text: text,
                level: level
            )
        }

        if isUppercaseHeading(text) {
            return Heading(
                text: text,
                level: max(
                    currentDepth,
                    1
                )
            )
        }

        return nil
    }

    private func numberedHeadingLevel(
        _ text: String
    ) -> Int? {
        let trimmed = text.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let firstSpace = trimmed.firstIndex(
            where: \.isWhitespace
        )

        let token: String

        if let firstSpace {
            token = String(
                trimmed[..<firstSpace]
            )
        } else {
            token = trimmed
        }

        if let level = parenthesizedNumberLevel(
            token
        ) {
            return level
        }

        if token.range(
            of: #"^\d+[ivxlcdm]+[.)]?$"#,
            options: [
                .regularExpression,
                .caseInsensitive
            ]
        ) != nil {
            return 2
        }

        let cleaned = token
            .trimmingCharacters(
                in: CharacterSet(
                    charactersIn: ".:)"
                )
            )

        let parts = cleaned
            .split(separator: ".")
            .map(String.init)

        guard !parts.isEmpty else {
            return nil
        }

        guard
            isNumber(parts[0])
                || isRoman(parts[0])
        else {
            return nil
        }

        guard
            parts
                .dropFirst()
                .allSatisfy(isNumber)
        else {
            return nil
        }

        if parts.count == 1,
           isRoman(parts[0]),
           !token.contains(".")
        {
            guard let firstSpace else {
                return nil
            }

            let remainder = String(
                trimmed[
                    trimmed.index(
                        after: firstSpace
                    )...
                ]
            )

            guard
                isUppercaseHeading(
                    remainder
                )
            else {
                return nil
            }
        }

        return parts.count
    }

    private func isLikelyNumberedHeading(
        _ text: String
    ) -> Bool {
        guard
            let firstSpace = text.firstIndex(
                where: \.isWhitespace
            )
        else {
            return true
        }

        let remainder = String(
            text[
                text.index(
                    after: firstSpace
                )...
            ]
        )
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !remainder.isEmpty else {
            return true
        }

        if isUppercaseHeading(
            remainder
        ) {
            return true
        }

        let wordCount = remainder
            .split(
                whereSeparator: \.isWhitespace
            )
            .count

        let looksLikeSentence =
            remainder.hasSuffix(".")
            || remainder.hasSuffix(";")

        return wordCount <= 10
            && !looksLikeSentence
    }

    private func parenthesizedNumberLevel(
        _ token: String
    ) -> Int? {
        guard
            token.range(
                of: #"^\d+(?:\([A-Za-z0-9]+\))+$"#,
                options: .regularExpression
            ) != nil
        else {
            return nil
        }

        let nesting = token.filter {
            $0 == "("
        }.count

        return 1 + nesting
    }

    private func isCriterionHeading(
        _ text: String
    ) -> Bool {
        text.range(
            of: #"^Criterion\s+[A-Za-z0-9]+"#,
            options: [
                .regularExpression,
                .caseInsensitive
            ]
        ) != nil
    }

    private func isAnnexHeading(
        _ text: String
    ) -> Bool {
        text.range(
            of: #"^(Annex|Appendix)\s+[A-Za-z0-9IVXLCDM]+"#,
            options: [
                .regularExpression,
                .caseInsensitive
            ]
        ) != nil
    }

    private func isUppercaseHeading(
        _ text: String
    ) -> Bool {
        guard text.count <= 120 else {
            return false
        }

        guard
            text.rangeOfCharacter(
                from: .letters
            ) != nil
        else {
            return false
        }

        return text
            == text.uppercased()
    }

    private func isNumber(
        _ value: String
    ) -> Bool {
        !value.isEmpty
            && value.allSatisfy(
                \.isNumber
            )
    }

    private func isRoman(
        _ value: String
    ) -> Bool {
        guard !value.isEmpty else {
            return false
        }

        let allowed = CharacterSet(
            charactersIn: "IVXLCDM"
        )

        return value
            .uppercased()
            .unicodeScalars
            .allSatisfy {
                allowed.contains($0)
            }
    }

    private func updatedPath(
        _ path: [String],
        heading: Heading
    ) -> [String] {
        let parentCount = min(
            max(
                heading.level - 1,
                0
            ),
            path.count
        )

        var updated = Array(
            path.prefix(
                parentCount
            )
        )

        updated.append(
            heading.text
        )

        return updated
    }

    // MARK: - Lists

    private func normalizedListItem(
        from content: DocumentBlockContent
    ) -> DocumentBlockContent? {
        switch content {
        case .listItem:
            return content

        case .title(let text),
             .paragraph(let text),
             .text(let text):
            guard
                let item = parseListItem(
                    text
                )
            else {
                return nil
            }

            return .listItem(
                marker: item.marker,
                text: item.text
            )

        case .table:
            return nil
        }
    }

    private func parseListItem(
        _ text: String
    ) -> ListItem? {
        let pattern =
            #"^(\([A-Za-z0-9]+\)|[-•▪◦‣])\s*(.+)$"#

        guard
            let expression =
                try? NSRegularExpression(
                    pattern: pattern
                )
        else {
            return nil
        }

        let range = NSRange(
            text.startIndex..<text.endIndex,
            in: text
        )

        guard
            let match =
                expression.firstMatch(
                    in: text,
                    range: range
                ),
            match.numberOfRanges == 3,
            let markerRange = Range(
                match.range(at: 1),
                in: text
            ),
            let textRange = Range(
                match.range(at: 2),
                in: text
            )
        else {
            return nil
        }

        return ListItem(
            marker: String(
                text[markerRange]
            ),
            text: String(
                text[textRange]
            )
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        )
    }

    private func resolvedKind(
        for content: DocumentBlockContent
    ) -> ResolvedBlockKind {
        switch content {
        case .table:
            return .table

        case .listItem:
            return .listItem

        case .title, .paragraph:
            return .paragraph

        case .text:
            return .text
        }
    }
}

private struct Heading {
    let text: String
    let level: Int
}

private struct ListItem {
    let marker: String
    let text: String
}
