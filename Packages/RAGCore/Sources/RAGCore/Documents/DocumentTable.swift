//
//  DocumentTable.swift
//  RAGCore
//
//  Created by Andrew Wallace on 02/09/26.
//

public struct DocumentTable: Sendable {
    public let rows: [[DocumentTableCell]]

    public init(rows: [[DocumentTableCell]]) {
        self.rows = rows
    }

    public var text: String {
        rows
            .map { row in
                row.map(\.text)
                    .joined(separator: "\t")
            }
            .joined(separator: "\n")
    }
}

public struct DocumentTableCell: Sendable {
    public let text: String
    public let rowRange: ClosedRange<Int>
    public let columnRange: ClosedRange<Int>

    public init(
        text: String,
        rowRange: ClosedRange<Int>,
        columnRange: ClosedRange<Int>
    ) {
        self.text = text
        self.rowRange = rowRange
        self.columnRange = columnRange
    }
}
