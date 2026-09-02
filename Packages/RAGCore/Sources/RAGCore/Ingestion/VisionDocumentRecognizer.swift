//
//  VisionDocumentRecognizer.swift
//  RAGCore
//
//  Created by Andrew Wallace on 02/09/26.
//

import CoreGraphics
import Foundation
import Vision

struct VisionDocumentRecognizer: Sendable {
    func recognize(
        image: CGImage,
        pageNumber: Int
    ) async throws -> [DocumentBlock] {
        var request = RecognizeDocumentsRequest()

        request.textRecognitionOptions.automaticallyDetectLanguage = false

        request.textRecognitionOptions.recognitionLanguages = [
            Locale.Language(identifier: "en")
        ]

        request.textRecognitionOptions.useLanguageCorrection = true

        request.textRecognitionOptions.minimumTextHeightFraction = 0.01

        let observations = try await request.perform(
            on: image,
            orientation: .up
        )

        guard let document = observations.first?.document else {
            return []
        }

        var candidates: [BlockCandidate] = []

        if let title = document.title {
            append(
                content: .title(title.transcript),
                region: title.boundingRegion,
                pageNumber: pageNumber,
                to: &candidates
            )
        }

        for paragraph in document.paragraphs {
            append(
                content: .paragraph(paragraph.transcript),
                region: paragraph.boundingRegion,
                pageNumber: pageNumber,
                to: &candidates
            )
        }

        for list in document.lists {
            for item in list.items {
                let marker = item.markerString
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

                let text = item.itemString
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

                guard !text.isEmpty else {
                    continue
                }

                append(
                    content: .listItem(
                        marker: marker.isEmpty
                            ? nil
                            : marker,
                        text: text
                    ),
                    region: item.content.boundingRegion,
                    pageNumber: pageNumber,
                    to: &candidates
                )
            }
        }

        for table in document.tables {
            let rows = table.rows.map { row in
                row.map { cell in
                    DocumentTableCell(
                        text: cell.content.text.transcript
                            .trimmingCharacters(
                                in: .whitespacesAndNewlines
                            ),
                        rowRange: cell.rowRange,
                        columnRange: cell.columnRange
                    )
                }
            }

            append(
                content: .table(
                    DocumentTable(rows: rows)
                ),
                region: table.boundingRegion,
                pageNumber: pageNumber,
                to: &candidates
            )
        }

        return
            candidates
            .sorted(by: readingOrder)
            .map(\.block)
    }

    private func append(
        content: DocumentBlockContent,
        region: NormalizedRegion,
        pageNumber: Int,
        to candidates: inout [BlockCandidate]
    ) {
        let text = content.text
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !text.isEmpty else {
            return
        }

        let minX = region.points.map(\.x).min() ?? 0
        let maxX = region.points.map(\.x).max() ?? 0
        let minY = region.points.map(\.y).min() ?? 0
        let maxY = region.points.map(\.y).max() ?? 0

        candidates.append(
            BlockCandidate(
                block: DocumentBlock(
                    pageNumber: pageNumber,
                    content: content,
                    bounds: DocumentBounds(
                        minX: Double(minX),
                        minY: Double(minY),
                        maxX: Double(maxX),
                        maxY: Double(maxY)
                    )
                ),
                top: maxY,
                left: minX
            )
        )
    }

    private func readingOrder(
        _ lhs: BlockCandidate,
        _ rhs: BlockCandidate
    ) -> Bool {
        let band: CGFloat = 0.01

        let lhsBand =
            (lhs.top / band).rounded()

        let rhsBand =
            (rhs.top / band).rounded()

        if lhsBand != rhsBand {
            return lhsBand > rhsBand
        }

        return lhs.left < rhs.left
    }
}

private struct BlockCandidate {
    let block: DocumentBlock
    let top: CGFloat
    let left: CGFloat
}
