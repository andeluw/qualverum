//
//  PDFViewerView.swift
//  Qualverum
//
//  Created by Andrew Wallace on 02/09/26.
//

import SwiftUI
import PDFKit

struct PDFViewerView: View {
    let request: PDFRequest?
    @Environment(DocumentService.self) private var documents

    private var url: URL? { documents.sampleURL(named: request?.resource) }

    var body: some View {
        Group {
            if let request {
                if let url {
                    PDFKitView(url: url, page: request.page)
                } else {
                    ContentUnavailableView {
                        Label("Document Unavailable", systemImage: "doc.questionmark")
                    } description: {
                        Text("\(request.title)\n\nThe source file is not indexed in this mock workspace. In the shipping app this opens the original PDF at page \(request.page).")
                            .multilineTextAlignment(.center)
                    }
                }
            } else {
                ContentUnavailableView("No Document", systemImage: "doc")
            }
        }
        .navigationTitle(request?.title ?? "Document")
    }
}

private struct PDFKitView: NSViewRepresentable {
    let url: URL
    let page: Int

    func makeNSView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.document = PDFDocument(url: url)
        goToPage(view)
        return view
    }

    func updateNSView(_ view: PDFView, context: Context) {
        if view.document?.documentURL != url {
            view.document = PDFDocument(url: url)
        }
        goToPage(view)
    }

    private func goToPage(_ view: PDFView) {
        // Citations start at page 1 but PDFKit starts at 0.
        if let doc = view.document, page > 0, page <= doc.pageCount,
           let target = doc.page(at: page - 1) {
            view.go(to: target)
        }
    }
}
