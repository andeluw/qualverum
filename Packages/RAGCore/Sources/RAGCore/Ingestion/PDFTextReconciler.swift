//
//  PDFTextReconciler.swift
//  RAGCore
//
//  Created by Andrew Wallace on 03/09/26.
//

import CoreGraphics
import Foundation
import PDFKit

struct PDFTextReconciler: Sendable {
    func reconcile(
        _ blocks: [DocumentBlock],
        page: PDFPage,
        image: CGImage
    ) -> [DocumentBlock] {
        guard
            let rawText = page.string?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
            !rawText.isEmpty,
            let pdfPage = page.pageRef
        else {
            return blocks
        }

        let imageRect = CGRect(
            x: 0,
            y: 0,
            width: image.width,
            height: image.height
        )

        let transform = pdfPage.getDrawingTransform(
            .cropBox,
            rect: imageRect,
            rotate: 0,
            preserveAspectRatio: true
        )

        let inverseTransform = transform.inverted()

        return blocks.map { block in
            reconcile(
                block,
                page: page,
                imageRect: imageRect,
                inverseTransform: inverseTransform
            )
        }
    }

    private func reconcile(
        _ block: DocumentBlock,
        page: PDFPage,
        imageRect: CGRect,
        inverseTransform: CGAffineTransform
    ) -> DocumentBlock {
        // Keep Vision's structured table.
        if case .table = block.content {
            return block
        }

        guard let bounds = block.bounds else {
            return block
        }

        let visionRect = CGRect(
            x: bounds.minX * imageRect.width,
            y: bounds.minY * imageRect.height,
            width: (bounds.maxX - bounds.minX) * imageRect.width,
            height: (bounds.maxY - bounds.minY) * imageRect.height
        )

        // Tight box first to stay on one line, then a wider one to
        // rescue boxes Vision drew too short, else keep the OCR text.
        let nativeText =
            nativeText(
                in: visionRect.insetBy(dx: -2, dy: 0),
                imageRect: imageRect,
                page: page,
                inverseTransform: inverseTransform
            )
            ?? nativeText(
                in: visionRect.insetBy(dx: -2, dy: -2),
                imageRect: imageRect,
                page: page,
                inverseTransform: inverseTransform
            )

        guard let nativeText else {
            return block
        }

        return DocumentBlock(
            pageNumber: block.pageNumber,
            content: replacingText(
                in: block.content,
                with: nativeText
            ),
            bounds: block.bounds
        )
    }

    private func nativeText(
        in rect: CGRect,
        imageRect: CGRect,
        page: PDFPage,
        inverseTransform: CGAffineTransform
    ) -> String? {
        let pageRect = rect
            .intersection(imageRect)
            .applying(inverseTransform)

        guard
            let selection = page.selection(
                for: pageRect
            ),
            let selectionText = selection.string
        else {
            return nil
        }

        let normalized = normalizedWhitespace(
            selectionText
        )

        return normalized.isEmpty
            ? nil
            : normalized
    }

    private func replacingText(
        in content: DocumentBlockContent,
        with text: String
    ) -> DocumentBlockContent {
        switch content {
        case .title:
            return .title(text)

        case .paragraph:
            return .paragraph(text)

        case .listItem(let marker, _):
            guard let marker else {
                return .listItem(
                    marker: nil,
                    text: text
                )
            }

            if text.hasPrefix(marker) {
                return .listItem(
                    marker: marker,
                    text: removingMarker(
                        marker,
                        from: text
                    )
                )
            }

            return .listItem(
                marker: nil,
                text: text
            )

        case .table:
            return content

        case .text:
            return .text(text)
        }
    }

    private func removingMarker(
        _ marker: String?,
        from text: String
    ) -> String {
        guard
            let marker,
            text.hasPrefix(marker)
        else {
            return text
        }

        return String(
            text.dropFirst(marker.count)
        )
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private func normalizedWhitespace(
        _ text: String
    ) -> String {
        text
            .split(
                whereSeparator: \.isWhitespace
            )
            .joined(separator: " ")
    }
}
