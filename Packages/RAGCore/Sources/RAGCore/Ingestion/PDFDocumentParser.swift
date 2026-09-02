//
//  PDFDocumentParser.swift
//  RAGCore
//
//  Created by Andrew Wallace on 02/09/26.
//

import CoreGraphics
import Foundation
import PDFKit

public struct PDFDocumentParser: DocumentParser {
    private let renderer: PDFPageRenderer
    private let recognizer: VisionDocumentRecognizer
    private let reconciler: PDFTextReconciler
    private let cleaner: DocumentCleaner

    public init(
        renderScale: CGFloat = 2.0
    ) {
        renderer = PDFPageRenderer(
            scale: renderScale
        )

        recognizer =
            VisionDocumentRecognizer()

        reconciler =
            PDFTextReconciler()

        cleaner =
            DocumentCleaner()
    }

    public func parse(
        url: URL
    ) async throws -> ParsedDocument {
        guard let pdf = PDFDocument(
            url: url
        ) else {
            throw PDFDocumentParserError
                .invalidDocument
        }

        var pages: [ParsedPage] = []

        for index in 0..<pdf.pageCount {
            guard let page = pdf.page(
                at: index
            ) else {
                continue
            }

            let pageNumber = index + 1

            let rawText = page.string?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            ?? ""

            let image = try renderer.render(
                page
            )

            let visionBlocks =
                try await recognizer.recognize(
                    image: image,
                    pageNumber: pageNumber
                )

            let blocks =
                reconciler.reconcile(
                    visionBlocks,
                    page: page,
                    image: image
                )

            pages.append(
                ParsedPage(
                    number: pageNumber,
                    rawText: rawText,
                    blocks: blocks
                )
            )
        }

        let document = ParsedDocument(
            id: url.lastPathComponent,
            title: url
                .deletingPathExtension()
                .lastPathComponent,
            pages: pages
        )

        return cleaner.clean(document)
    }
}

public enum PDFDocumentParserError: Error {
    case invalidDocument
}
