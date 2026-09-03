//
//  RetrievalContext.swift
//  RAGCore
//
//  Created by Andrew Wallace on 03/09/26.
//

public struct RetrievalContext: Sendable {
    public let text: String
    public let results: [RetrievalResult]

    public init(
        text: String,
        results: [RetrievalResult]
    ) {
        self.text = text
        self.results = results
    }
}
