//
//  DenseRetrievalDebugView.swift
//  Qualverum
//
//  Created by Andrew Wallace on 03/09/26.
//

#if DEBUG

import RAGCore
import SwiftUI
import UniformTypeIdentifiers

struct DenseRetrievalDebugView: View {
    @State private var provider: EmbeddingGemmaProvider?
    @State private var retriever: ExactDenseRetriever?

    @State private var documentTitle = ""
    @State private var indexedChunkCount = 0

    @State private var query =
        "How long is the framework contract valid?"

    @State private var topK = 5
    @State private var results: [RetrievalResult] = []

    @State private var isImporting = false
    @State private var isLoadingModel = false
    @State private var isIndexing = false
    @State private var isSearching = false

    @State private var status = "Load the embedding model first."
    @State private var errorMessage: String?

    @State private var downloadProgress: Double?
    @State private var currentFile = ""

    @State private var indexingTime: TimeInterval?
    @State private var searchTime: TimeInterval?

    private let renderScale: CGFloat = 1.0
    private let maxWords = 180

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: 28
            ) {
                modelSection
                indexSection
                searchSection
                resultsSection
            }
            .padding(32)
            .frame(
                maxWidth: 900,
                alignment: .leading
            )
        }
        .navigationTitle("Dense Retrieval Debug")
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
    }

    // MARK: - Model

    private var modelSection: some View {
        GroupBox("Embedding Model") {
            VStack(
                alignment: .leading,
                spacing: 12
            ) {
                HStack {
                    if isLoadingModel {
                        ProgressView()
                            .controlSize(.small)
                    }

                    Text(
                        provider == nil
                            ? status
                            : "EmbeddingGemma loaded"
                    )

                    Spacer()

                    Button("Load Model") {
                        Task {
                            await loadModel()
                        }
                    }
                    .disabled(
                        isLoadingModel || provider != nil
                    )
                }

                if let downloadProgress {
                    ProgressView(
                        value: downloadProgress
                    )

                    HStack {
                        Text(
                            "\(Int(downloadProgress * 100))%"
                        )

                        Spacer()

                        if !currentFile.isEmpty {
                            Text(currentFile)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(8)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
    }

    // MARK: - Index

    private var indexSection: some View {
        GroupBox("Dense Index") {
            VStack(
                alignment: .leading,
                spacing: 12
            ) {
                HStack {
                    Button("Choose PDF and Build Index") {
                        isImporting = true
                    }
                    .disabled(
                        provider == nil
                            || isIndexing
                            || isSearching
                    )

                    if isIndexing {
                        ProgressView()
                            .controlSize(.small)

                        Text("Indexing…")
                            .foregroundStyle(.secondary)
                    }
                }

                if !documentTitle.isEmpty {
                    LabeledContent(
                        "Document",
                        value: documentTitle
                    )

                    LabeledContent(
                        "Indexed children",
                        value: "\(indexedChunkCount)"
                    )

                    if let indexingTime {
                        LabeledContent(
                            "Indexing time",
                            value: String(
                                format: "%.2f s",
                                indexingTime
                            )
                        )
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .textSelection(.enabled)
                }
            }
            .padding(8)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
    }

    // MARK: - Search

    private var searchSection: some View {
        GroupBox("Search") {
            VStack(
                alignment: .leading,
                spacing: 12
            ) {
                TextField(
                    "Query",
                    text: $query,
                    axis: .vertical
                )
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...5)

                HStack {
                    Stepper(
                        "Top K: \(topK)",
                        value: $topK,
                        in: 1...20
                    )
                    .frame(maxWidth: 160)

                    Spacer()

                    if isSearching {
                        ProgressView()
                            .controlSize(.small)
                    }

                    Button("Search") {
                        Task {
                            await search()
                        }
                    }
                    .keyboardShortcut(.return)
                    .disabled(
                        retriever == nil
                            || query
                                .trimmingCharacters(
                                    in: .whitespacesAndNewlines
                                )
                                .isEmpty
                            || isSearching
                            || isIndexing
                    )
                }

                if let searchTime {
                    Text(
                        String(
                            format:
                                "Search time: %.4f s",
                            searchTime
                        )
                    )
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                }
            }
            .padding(8)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
    }

    // MARK: - Results

    @ViewBuilder
    private var resultsSection: some View {
        if !results.isEmpty {
            VStack(
                alignment: .leading,
                spacing: 12
            ) {
                Text("Results")
                    .font(.headline)

                ForEach(
                    Array(results.enumerated()),
                    id: \.element.chunk.id
                ) { index, result in
                    resultCard(
                        result,
                        rank: index + 1
                    )
                }
            }
        }
    }

    private func resultCard(
        _ result: RetrievalResult,
        rank: Int
    ) -> some View {
        GroupBox {
            VStack(
                alignment: .leading,
                spacing: 10
            ) {
                HStack(
                    alignment: .firstTextBaseline
                ) {
                    Text("#\(rank)")
                        .font(.headline)

                    Text(
                        String(
                            format:
                                "score %.4f",
                            result.score
                        )
                    )
                    .font(.system(
                        .callout,
                        design: .monospaced
                    ))
                    .fontWeight(.medium)

                    Spacer()

                    Text(
                        "Page \(result.chunk.pageNumber)"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                if !result.chunk.sectionPath.isEmpty {
                    Label(
                        result.chunk.sectionPath
                            .joined(separator: " › "),
                        systemImage:
                            "arrow.turn.down.right"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                }

                Text(result.chunk.text)
                    .textSelection(.enabled)

                Divider()

                HStack {
                    Text(result.chunk.id)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()

                    Text(result.chunk.documentID)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .font(.caption.monospaced())
                .foregroundStyle(.tertiary)
            }
            .padding(6)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
    }

    // MARK: - Model Loading

    @MainActor
    private func loadModel() async {
        guard provider == nil else {
            return
        }

        isLoadingModel = true
        errorMessage = nil
        status = "Preparing…"

        defer {
            isLoadingModel = false
            downloadProgress = nil
            currentFile = ""
        }

        do {
            provider =
                try await EmbeddingGemmaProvider {
                    state in

                    Task { @MainActor in
                        switch state {
                        case .downloading(
                            let progress,
                            let file
                        ):
                            status = "Downloading…"
                            downloadProgress =
                                progress
                            currentFile = file

                        case .loading:
                            status = "Loading model…"
                            downloadProgress = nil
                            currentFile = ""
                        }
                    }
                }

            status = "Loaded"
        } catch {
            errorMessage =
                "Model load failed: \(error.localizedDescription)"

            status = "Failed"
        }
    }

    // MARK: - Import / Index

    private func handleImport(
        _ result: Result<[URL], Error>
    ) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                return
            }

            Task {
                await buildIndex(from: url)
            }

        case .failure(let error):
            errorMessage =
                error.localizedDescription
        }
    }

    @MainActor
    private func buildIndex(
        from url: URL
    ) async {
        guard let provider else {
            errorMessage =
                "Load the embedding model first."
            return
        }

        isIndexing = true
        errorMessage = nil

        retriever = nil
        results = []
        documentTitle = ""
        indexedChunkCount = 0
        indexingTime = nil
        searchTime = nil

        let hasAccess =
            url.startAccessingSecurityScopedResource()

        defer {
            if hasAccess {
                url.stopAccessingSecurityScopedResource()
            }

            isIndexing = false
        }

        do {
            let startedAt = Date()

            let parser = PDFDocumentParser(
                renderScale: renderScale
            )

            let document =
                try await parser.parse(
                    url: url
                )

            let chunker =
                StructureAwareChunker(
                    maxWords: maxWords
                )

            let chunks =
                chunker.chunk(document)

            let children =
                chunks.filter { chunk in
                    switch chunk.kind {
                    case .child:
                        return true

                    case .parent:
                        return false
                    }
                }

            let builder =
                DenseIndexBuilder(
                    embeddingProvider: provider
                )

            let entries =
                try await builder.build(
                    from: children
                )

            let denseRetriever =
                try ExactDenseRetriever(
                    entries: entries
                )

            retriever = denseRetriever
            documentTitle = document.title
            indexedChunkCount = entries.count

            indexingTime =
                Date().timeIntervalSince(
                    startedAt
                )

            status =
                "Indexed \(entries.count) child chunks"

        } catch {
            errorMessage =
                "Indexing failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Search

    @MainActor
    private func search() async {
        guard
            let provider,
            let retriever
        else {
            return
        }

        let trimmedQuery =
            query.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !trimmedQuery.isEmpty else {
            return
        }

        isSearching = true
        errorMessage = nil
        results = []
        searchTime = nil

        defer {
            isSearching = false
        }

        do {
            let startedAt = Date()

            let values =
                try await provider.embedQuery(
                    trimmedQuery
                )

            let queryVector =
                try EmbeddingVector(
                    values: values
                )

            results =
                try await retriever.retrieve(
                    query: queryVector,
                    topK: topK
                )

            searchTime =
                Date().timeIntervalSince(
                    startedAt
                )

        } catch {
            errorMessage =
                "Search failed: \(error.localizedDescription)"
        }
    }
}

#Preview {
    NavigationStack {
        DenseRetrievalDebugView()
    }
}

#endif
