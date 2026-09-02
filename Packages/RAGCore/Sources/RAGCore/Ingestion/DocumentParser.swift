//
//  DocumentParser.swift
//  RAGCore
//
//  Created by Andrew Wallace on 02/09/26.
//

import Foundation

public protocol DocumentParser: Sendable {
    func parse(url: URL) async throws -> ParsedDocument
}
