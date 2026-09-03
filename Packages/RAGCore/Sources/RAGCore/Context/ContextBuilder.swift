//
//  ContextBuilder.swift
//  RAGCore
//
//  Created by Andrew Wallace on 03/09/26.
//

public struct ContextBuilder: Sendable {
    public init() {}

    public func build(
        from results: [RetrievalResult]
    ) -> RetrievalContext {
        let text =
            results.enumerated()
                .map { index, result in
                    let chunk =
                        result.chunk

                    let section =
                        chunk.sectionPath.isEmpty
                        ? "Unknown"
                        : chunk.sectionPath
                            .joined(separator: " > ")

                    return """
                    [Evidence \(index + 1)]
                    Document: \(chunk.documentID)
                    Page: \(chunk.pageNumber)
                    Section: \(section)

                    \(chunk.text)
                    """
                }
                .joined(
                    separator: "\n\n"
                )

        return RetrievalContext(
            text: text,
            results: results
        )
    }
}
