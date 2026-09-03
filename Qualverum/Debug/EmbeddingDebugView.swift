import RAGCore
import SwiftUI

struct EmbeddingDebugView: View {
    @State private var provider: EmbeddingGemmaProvider?

    @State private var status = "Not loaded"
    @State private var isLoading = false
    @State private var downloadProgress: Double?
    @State private var currentFile = ""
    @State private var loadStartedAt: Date?

    @State private var queryResult = ""
    @State private var documentResult = ""

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: 32
            ) {
                modelSection
                embeddingSection
            }
            .padding(32)
            .frame(
                maxWidth: 720,
                alignment: .leading
            )
        }
        .navigationTitle("Embedding Debug")
    }

    private var modelSection: some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            Text("Model")
                .font(.headline)

            GroupBox {
                VStack(
                    alignment: .leading,
                    spacing: 12
                ) {
                    HStack(spacing: 8) {
                        if isLoading {
                            ProgressView()
                                .controlSize(.small)
                        }

                        Text(status)
                            .font(.title3)
                            .fontWeight(.medium)
                    }

                    if let progress = downloadProgress {
                        ProgressView(value: progress)

                        HStack {
                            Text(
                                "\(Int(progress * 100))%"
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

                    if isLoading,
                        let loadStartedAt
                    {
                        TimelineView(
                            .periodic(
                                from: .now,
                                by: 0.5
                            )
                        ) { context in
                            let elapsed =
                                context.date
                                .timeIntervalSince(
                                    loadStartedAt
                                )

                            Text(
                                String(
                                    format:
                                        "Elapsed: %.1f s",
                                    elapsed
                                )
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }

                    Button("Load Model") {
                        Task {
                            await loadModel()
                        }
                    }
                    .disabled(
                        isLoading || provider != nil
                    )
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .padding(8)
            }
        }
    }

    private var embeddingSection: some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            Text("Embedding Test")
                .font(.headline)

            GroupBox {
                VStack(
                    alignment: .leading,
                    spacing: 20
                ) {
                    Button("Run Embedding") {
                        Task {
                            await runEmbedding()
                        }
                    }
                    .disabled(provider == nil)

                    if !queryResult.isEmpty {
                        resultSection(
                            title: "Query",
                            result: queryResult
                        )
                    }

                    if !documentResult.isEmpty {
                        resultSection(
                            title: "Document",
                            result: documentResult
                        )
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .padding(8)
            }
        }
    }

    private func resultSection(
        title: String,
        result: String
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 6
        ) {
            Text(title)
                .font(.headline)

            Text(result)
                .monospaced()
                .textSelection(.enabled)
        }
    }

    @MainActor
    private func loadModel() async {
        isLoading = true
        status = "Preparing..."
        loadStartedAt = .now
        downloadProgress = nil
        currentFile = ""

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
                            status = "Downloading..."
                            downloadProgress =
                                progress
                            currentFile = file

                        case .loading:
                            status = "Loading model..."
                            loadStartedAt = .now
                            downloadProgress = nil
                            currentFile = ""
                        }
                    }
                }

            status = "Loaded"
        } catch {
            status =
                "Failed: \(error.localizedDescription)"
        }

        isLoading = false
        loadStartedAt = nil
        downloadProgress = nil
        currentFile = ""
    }

    @MainActor
    private func runEmbedding() async {
        guard let provider else {
            return
        }

        queryResult = "Running..."
        documentResult = "Running..."

        do {
            let query =
                try await provider.embedQuery(
                    "How long is the framework contract valid?"
                )

            let document =
                try await provider.embedDocument(
                    """
                    The FWC is concluded for a \
                    period of 12 months.
                    """
                )

            queryResult = summary(
                for: query
            )

            documentResult = summary(
                for: document
            )
        } catch {
            queryResult =
                "Failed: \(error.localizedDescription)"

            documentResult = ""
        }
    }

    private func summary(
        for embedding: [Float]
    ) -> String {
        let norm = sqrt(
            embedding.reduce(0) {
                $0 + $1 * $1
            }
        )

        let values =
            embedding
            .prefix(8)
            .map {
                String(
                    format: "%.4f",
                    $0
                )
            }
            .joined(separator: ", ")

        return """
            dimension: \(embedding.count)
            finite: \(embedding.allSatisfy(\.isFinite))
            norm: \(String(format: "%.4f", norm))
            [\(values), ...]
            """
    }
}

#Preview {
    NavigationStack {
        EmbeddingDebugView()
    }
}
