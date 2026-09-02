//
//  DocumentPipelineDebugView.swift
//  Qualverum
//
//  Created by Andrew Wallace on 03/09/26.
//

#if DEBUG

import AppKit
import PDFKit
import RAGCore
import SwiftUI
import UniformTypeIdentifiers

struct DocumentPipelineDebugView: View {
    @State private var document: ParsedDocument?
    @State private var resolvedDocument: ResolvedDocument?
    @State private var chunks: [DocumentChunk] = []

    @State private var pdfURL: URL?
    @State private var renderedImage: CGImage?

    @State private var selectedPageNumber: Int?

    @State private var isImporting = false
    @State private var isParsing = false
    @State private var errorMessage: String?

    private let renderScale: CGFloat = 1.0
    private let maxWords = 180

    private var renderer: PDFPageRenderer {
        PDFPageRenderer(scale: renderScale)
    }

    private var selectedPage: ParsedPage? {
        guard let document else {
            return nil
        }

        guard let selectedPageNumber else {
            return document.pages.first
        }

        return document.pages.first {
            $0.number == selectedPageNumber
        }
    }

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(
                    min: 170,
                    ideal: 190
                )
        } detail: {
            detail
        }
        .navigationTitle(
            document?.title ?? "Document Pipeline"
        )
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isImporting = true
                } label: {
                    Label(
                        "Choose PDF",
                        systemImage: "doc.badge.plus"
                    )
                }
            }

            if let page = selectedPage {
                ToolbarItem {
                    Button {
                        copyDebugOutput(for: page)
                    } label: {
                        Label(
                            "Copy Debug",
                            systemImage: "doc.on.clipboard"
                        )
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .onChange(of: selectedPageNumber) {
            updateRenderedPage()
        }
    }

    // MARK: - Sidebar

    @ViewBuilder
    private var sidebar: some View {
        if let document {
            List(selection: $selectedPageNumber) {
                Section("\(document.pages.count) Pages") {
                    ForEach(
                        document.pages,
                        id: \.number
                    ) { page in
                        HStack {
                            Text("Page \(page.number)")

                            Spacer()

                            Text("\(page.blocks.count)")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        .tag(page.number)
                    }
                }
            }
        } else {
            List {}
                .overlay {
                    Text("No document loaded")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
        }
    }

    // MARK: - Detail

    @ViewBuilder
    private var detail: some View {
        if isParsing {
            ProgressView("Parsing document…")
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )

        } else if let errorMessage {
            ContentUnavailableView(
                "Parsing Failed",
                systemImage: "exclamationmark.triangle",
                description: Text(errorMessage)
            )

        } else if let page = selectedPage {
            pageInspector(page)

        } else if document != nil {
            ContentUnavailableView(
                "Select a Page",
                systemImage: "sidebar.left",
                description: Text(
                    "Pick a page to inspect its pipeline."
                )
            )

        } else {
            ContentUnavailableView(
                "No PDF Selected",
                systemImage: "doc.text.magnifyingglass",
                description: Text(
                    "Choose a PDF to inspect the document pipeline."
                )
            )
        }
    }

    // MARK: - Inspector

    private func pageInspector(
        _ page: ParsedPage
    ) -> some View {
        ScrollView {
            LazyVStack(
                alignment: .leading,
                spacing: 32
            ) {
                renderedPageSection
                rawTextSection(page)
                visionBlocksSection(page)
                resolvedHierarchySection(page)
                chunksSection(page)
            }
            .padding()
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
    }

    // MARK: - Rendered Page

    private var renderedPageSection: some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            sectionHeader(
                icon: "photo",
                title: "Rendered Page",
                detail:
                    "Vision input • \(String(format: "%.1f", Double(renderScale)))×"
            )

            if let renderedImage {
                Image(
                    decorative: renderedImage,
                    scale: 1,
                    orientation: .up
                )
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 750)
                .background(.white)
                .clipShape(
                    RoundedRectangle(cornerRadius: 8)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            Color(.separatorColor),
                            lineWidth: 0.5
                        )
                )
                .shadow(
                    color: .black.opacity(0.12),
                    radius: 8,
                    y: 2
                )

                Text(
                    "\(renderedImage.width) × \(renderedImage.height) px"
                )
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)

            } else {
                ContentUnavailableView(
                    "Unable to Render Page",
                    systemImage: "doc.questionmark"
                )
                .frame(minHeight: 200)
            }
        }
    }

    // MARK: - PDFKit

    private func rawTextSection(
        _ page: ParsedPage
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            sectionHeader(
                icon: "doc.plaintext",
                title: "PDFKit Raw Text",
                detail: "\(page.rawText.count) characters"
            )

            debugCard {
                Text(
                    page.rawText.isEmpty
                        ? "No native text detected."
                        : page.rawText
                )
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(
                    page.rawText.isEmpty
                        ? Color.secondary
                        : Color.primary
                )
                .textSelection(.enabled)
            }
        }
    }

    // MARK: - Vision

    private func visionBlocksSection(
        _ page: ParsedPage
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            sectionHeader(
                icon: "eye",
                title: "Vision Blocks",
                detail: "\(page.blocks.count) blocks"
            )

            if page.blocks.isEmpty {
                Text("No Vision blocks detected.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(
                    Array(page.blocks.enumerated()),
                    id: \.offset
                ) { index, block in
                    visionBlockView(
                        block,
                        index: index
                    )
                }
            }
        }
    }

    private func visionBlockView(
        _ block: DocumentBlock,
        index: Int
    ) -> some View {
        debugCard {
            HStack(alignment: .firstTextBaseline) {
                Text("#\(index + 1)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)

                badge(blockType(block.content))

                Spacer()

                if let bounds = block.bounds {
                    Text(boundsDescription(bounds))
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }

            Text(block.text)
                .textSelection(.enabled)
        }
    }

    // MARK: - Resolved Hierarchy

    private func resolvedHierarchySection(
        _ page: ParsedPage
    ) -> some View {
        let blocks = resolvedBlocks(for: page)

        return VStack(
            alignment: .leading,
            spacing: 12
        ) {
            sectionHeader(
                icon: "list.bullet.indent",
                title: "Resolved Hierarchy",
                detail: "\(blocks.count) blocks"
            )

            if blocks.isEmpty {
                Text("No resolved blocks.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(
                    Array(blocks.enumerated()),
                    id: \.offset
                ) { index, block in
                    resolvedBlockView(
                        block,
                        index: index
                    )
                }
            }
        }
    }

    private func resolvedBlockView(
        _ block: ResolvedBlock,
        index: Int
    ) -> some View {
        debugCard(
            indent: hierarchyIndent(for: block)
        ) {
            HStack(alignment: .firstTextBaseline) {
                Text("#\(index + 1)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)

                badge(resolvedKind(block.kind))

                Spacer()

                Text(blockType(block.content))
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }

            if !block.sectionPath.isEmpty {
                Label(
                    block.sectionPath.joined(
                        separator: " › "
                    ),
                    systemImage: "arrow.turn.down.right"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
            }

            Text(block.text)
                .textSelection(.enabled)
        }
    }

    private func resolvedBlocks(
        for page: ParsedPage
    ) -> [ResolvedBlock] {
        resolvedDocument?.blocks.filter {
            $0.pageNumber == page.number
        } ?? []
    }

    // MARK: - Chunks

    private func chunksSection(
        _ page: ParsedPage
    ) -> some View {
        let pageChunks = chunks.filter {
            $0.pageNumber == page.number
        }

        return VStack(
            alignment: .leading,
            spacing: 12
        ) {
            sectionHeader(
                icon: "square.stack.3d.up",
                title: "Chunks Starting on Page",
                detail:
                    "\(pageChunks.count) chunks • max \(maxWords) words"
            )

            if pageChunks.isEmpty {
                Text("No chunks start on this page.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(
                    Array(pageChunks.enumerated()),
                    id: \.offset
                ) { index, chunk in
                    chunkView(
                        chunk,
                        index: index
                    )
                }
            }
        }
    }

    private func chunkView(
        _ chunk: DocumentChunk,
        index: Int
    ) -> some View {
        debugCard(
            indent: chunkIndent(chunk.kind)
        ) {
            HStack(alignment: .firstTextBaseline) {
                Text("#\(index + 1)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)

                badge(chunkKind(chunk.kind))

                Spacer()

                Text(chunk.id)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            if !chunk.sectionPath.isEmpty {
                Label(
                    chunk.sectionPath.joined(
                        separator: " › "
                    ),
                    systemImage: "arrow.turn.down.right"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
            }

            if let parentID = chunk.parentID {
                Label(
                    parentID,
                    systemImage: "arrow.up.forward"
                )
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .lineLimit(1)
                .truncationMode(.middle)
            }

            Text(chunk.text)
                .textSelection(.enabled)
        }
    }

    // MARK: - Debug Output

    private func copyDebugOutput(
        for page: ParsedPage
    ) {
        let output = debugOutput(for: page)

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(
            output,
            forType: .string
        )

        print(output)
    }

    private func debugOutput(
        for page: ParsedPage
    ) -> String {
        var output: [String] = []

        output.append(
            """
            ========================================
            DOCUMENT PIPELINE DEBUG
            ========================================

            Page: \(page.number)
            """
        )

        // PDFKit

        output.append(
            """
            ========================================
            PDFKIT RAW TEXT
            ========================================

            \(page.rawText.isEmpty ? "[EMPTY]" : page.rawText)
            """
        )

        // Vision

        output.append(
            """
            ========================================
            VISION BLOCKS
            ========================================
            """
        )

        if page.blocks.isEmpty {
            output.append(
                "[NO VISION BLOCKS]"
            )
        } else {
            for (
                index,
                block
            ) in page.blocks.enumerated() {
                var lines: [String] = []

                lines.append(
                    "[\(index + 1)] \(blockType(block.content))"
                )

                if let bounds = block.bounds {
                    lines.append(
                        "Bounds: \(boundsDescription(bounds))"
                    )
                }

                lines.append(
                    """
                    Text:
                    \(block.text)
                    """
                )

                output.append(
                    lines.joined(separator: "\n")
                )
            }
        }

        // Resolved hierarchy

        output.append(
            """
            ========================================
            RESOLVED HIERARCHY
            ========================================
            """
        )

        let pageResolvedBlocks =
            resolvedBlocks(for: page)

        if pageResolvedBlocks.isEmpty {
            output.append(
                "[NO RESOLVED BLOCKS]"
            )
        } else {
            for (
                index,
                block
            ) in pageResolvedBlocks.enumerated() {
                var lines: [String] = []

                lines.append(
                    "[\(index + 1)] \(resolvedKind(block.kind))"
                )

                if block.sectionPath.isEmpty {
                    lines.append(
                        "Path: [ROOT]"
                    )
                } else {
                    lines.append(
                        "Path: \(block.sectionPath.joined(separator: " > "))"
                    )
                }

                lines.append(
                    "Source Type: \(blockType(block.content))"
                )

                if let bounds = block.bounds {
                    lines.append(
                        "Bounds: \(boundsDescription(bounds))"
                    )
                }

                lines.append(
                    """
                    Text:
                    \(block.text)
                    """
                )

                output.append(
                    lines.joined(separator: "\n")
                )
            }
        }

        // Chunks

        output.append(
            """
            ========================================
            CHUNKS STARTING ON PAGE
            ========================================
            """
        )

        let pageChunks = chunks.filter {
            $0.pageNumber == page.number
        }

        if pageChunks.isEmpty {
            output.append(
                "[NO CHUNKS]"
            )
        } else {
            for (
                index,
                chunk
            ) in pageChunks.enumerated() {
                var lines: [String] = []

                lines.append(
                    "[\(index + 1)] \(chunkKind(chunk.kind))"
                )

                lines.append(
                    "ID: \(chunk.id)"
                )

                if let parentID = chunk.parentID {
                    lines.append(
                        "Parent: \(parentID)"
                    )
                }

                if chunk.sectionPath.isEmpty {
                    lines.append(
                        "Path: [ROOT]"
                    )
                } else {
                    lines.append(
                        "Path: \(chunk.sectionPath.joined(separator: " > "))"
                    )
                }

                lines.append(
                    """
                    Text:
                    \(chunk.text)
                    """
                )

                output.append(
                    lines.joined(separator: "\n")
                )
            }
        }

        return output.joined(
            separator: "\n\n"
        )
    }

    // MARK: - Helpers

    private func sectionHeader(
        icon: String,
        title: String,
        detail: String
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.title3)
                .fontWeight(.semibold)

            Spacer()

            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func badge(
        _ text: String
    ) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(.quaternary, in: Capsule())
    }

    private func debugCard<Content: View>(
        indent: CGFloat = 0,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            content()
        }
        .padding(12)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.quaternary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    Color(.separatorColor),
                    lineWidth: 0.5
                )
        )
        .padding(.leading, indent)
    }

    private func blockType(
        _ content: DocumentBlockContent
    ) -> String {
        switch content {
        case .title:
            return "TITLE"

        case .paragraph:
            return "PARAGRAPH"

        case .listItem(let marker, _):
            if let marker {
                return "LIST \(marker)"
            }

            return "LIST"

        case .table:
            return "TABLE"

        case .text:
            return "TEXT"
        }
    }

    private func resolvedKind(
        _ kind: ResolvedBlockKind
    ) -> String {
        switch kind {
        case .heading(let level):
            return "HEADING L\(level)"

        case .paragraph:
            return "PARAGRAPH"

        case .listItem:
            return "LIST ITEM"

        case .table:
            return "TABLE"

        case .text:
            return "TEXT"
        }
    }

    private func chunkKind(
        _ kind: DocumentChunkKind
    ) -> String {
        switch kind {
        case .parent:
            return "PARENT"

        case .child:
            return "CHILD"
        }
    }

    private func hierarchyIndent(
        for block: ResolvedBlock
    ) -> CGFloat {
        CGFloat(
            max(
                block.sectionPath.count - 1,
                0
            )
        ) * 12
    }

    private func chunkIndent(
        _ kind: DocumentChunkKind
    ) -> CGFloat {
        switch kind {
        case .parent:
            return 0

        case .child:
            return 16
        }
    }

    private func boundsDescription(
        _ bounds: DocumentBounds
    ) -> String {
        String(
            format: "%.3f, %.3f → %.3f, %.3f",
            bounds.minX,
            bounds.minY,
            bounds.maxX,
            bounds.maxY
        )
    }

    // MARK: - Import

    private func handleImport(
        _ result: Result<[URL], Error>
    ) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                return
            }

            Task {
                await parse(url)
            }

        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func parse(
        _ url: URL
    ) async {
        isParsing = true
        errorMessage = nil

        document = nil
        resolvedDocument = nil
        chunks = []

        renderedImage = nil
        selectedPageNumber = nil

        let hasAccess =
            url.startAccessingSecurityScopedResource()

        defer {
            if hasAccess {
                url.stopAccessingSecurityScopedResource()
            }

            isParsing = false
        }

        do {
            let parser = PDFDocumentParser(
                renderScale: renderScale
            )

            let parsed = try await parser.parse(
                url: url
            )

            let resolver =
                StructureHierarchyResolver()

            let resolved =
                resolver.resolve(parsed)

            let chunker =
                StructureAwareChunker(
                    maxWords: maxWords
                )

            let documentChunks =
                chunker.chunk(parsed)

            pdfURL = url
            document = parsed
            resolvedDocument = resolved
            chunks = documentChunks

            selectedPageNumber =
                parsed.pages.first?.number

            updateRenderedPage()

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Render Inspection

    @MainActor
    private func updateRenderedPage() {
        guard
            let pdfURL,
            let pageNumber = selectedPageNumber
        else {
            renderedImage = nil
            return
        }

        let hasAccess =
            pdfURL.startAccessingSecurityScopedResource()

        defer {
            if hasAccess {
                pdfURL.stopAccessingSecurityScopedResource()
            }
        }

        guard
            let pdf = PDFDocument(url: pdfURL),
            let page = pdf.page(at: pageNumber - 1)
        else {
            renderedImage = nil
            return
        }

        do {
            renderedImage = try renderer.render(
                page
            )
        } catch {
            renderedImage = nil
            errorMessage = error.localizedDescription
        }
    }
}

#endif
