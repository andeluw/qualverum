//
//  PDFPageRenderer.swift
//  RAGCore
//
//  Created by Andrew Wallace on 03/09/26.
//

import CoreGraphics
import PDFKit

public struct PDFPageRenderer: Sendable {
    public let scale: CGFloat

    public init(scale: CGFloat = 2.0) {
        self.scale = scale
    }

    public func render(_ page: PDFPage) throws -> CGImage {
        guard let pdfPage = page.pageRef else {
            throw PDFPageRendererError.missingPageReference
        }

        let cropBox = pdfPage.getBoxRect(.cropBox)

        guard cropBox.width > 0, cropBox.height > 0 else {
            throw PDFPageRendererError.invalidPageBounds
        }

        let rotation = normalizedRotation(pdfPage.rotationAngle)
        let isSideways = rotation == 90 || rotation == 270

        let width = isSideways
            ? cropBox.height * scale
            : cropBox.width * scale

        let height = isSideways
            ? cropBox.width * scale
            : cropBox.height * scale

        let pixelWidth = max(
            Int(width.rounded(.up)),
            1
        )

        let pixelHeight = max(
            Int(height.rounded(.up)),
            1
        )

        guard let context = CGContext(
            data: nil,
            width: pixelWidth,
            height: pixelHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw PDFPageRendererError.renderingFailed
        }

        let targetRect = CGRect(
            x: 0,
            y: 0,
            width: pixelWidth,
            height: pixelHeight
        )

        context.setFillColor(
            CGColor(
                red: 1,
                green: 1,
                blue: 1,
                alpha: 1
            )
        )

        context.fill(targetRect)

        let transform = pdfPage.getDrawingTransform(
            .cropBox,
            rect: targetRect,
            rotate: 0,
            preserveAspectRatio: true
        )

        context.concatenate(transform)
        context.drawPDFPage(pdfPage)

        guard let image = context.makeImage() else {
            throw PDFPageRendererError.renderingFailed
        }

        return image
    }

    private func normalizedRotation(_ rotation: Int32) -> Int32 {
        let value = rotation % 360
        return value >= 0 ? value : value + 360
    }
}

public enum PDFPageRendererError: Error {
    case missingPageReference
    case invalidPageBounds
    case renderingFailed
}
