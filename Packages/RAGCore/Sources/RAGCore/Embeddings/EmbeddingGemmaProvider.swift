//
//  EmbeddingGemmaProvider.swift
//  RAGCore
//
//  Created by Andrew Wallace on 03/09/26.
//

import CoreMLLLM
import Foundation

public enum EmbeddingModelLoadState: Sendable {
    case downloading(
        progress: Double,
        file: String
    )
    case loading
}

public actor EmbeddingGemmaProvider: EmbeddingProvider {
    private let model: EmbeddingGemma
    public nonisolated let dimension = 768

    public init(
        onLoadState: (@Sendable (EmbeddingModelLoadState) -> Void)? = nil
    ) async throws {
        let modelsDirectory =
            FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            )[0]
            .appending(
                path: "RAGCore/MLModels",
                directoryHint: .isDirectory
            )

        try FileManager.default.createDirectory(
            at: modelsDirectory,
            withIntermediateDirectories: true
        )

        let bundleURL: URL

        if let cached =
            Gemma3BundleDownloader.localBundle(
                .embeddingGemma300m,
                under: modelsDirectory
            )
        {
            bundleURL = cached
        } else {
            onLoadState?(
                .downloading(
                    progress: 0,
                    file: ""
                )
            )

            bundleURL =
                try await Gemma3BundleDownloader.download(
                    .embeddingGemma300m,
                    into: modelsDirectory,
                    onProgress: { progress in
                        let percentage =
                            progress.bytesTotal > 0
                            ? Double(progress.bytesReceived)
                                / Double(progress.bytesTotal)
                            : 0

                        onLoadState?(
                            .downloading(
                                progress: percentage,
                                file: progress.currentFile
                            )
                        )
                    }
                )
        }

        onLoadState?(.loading)

        model = try await EmbeddingGemma.load(
            bundleURL: bundleURL
        )
    }

    public func embedQuery(
        _ text: String
    ) async throws -> [Float] {
        try model.encode(
            text: text,
            task: .retrievalQuery,
            dim: dimension
        )
    }

    public func embedDocument(
        _ text: String
    ) async throws -> [Float] {
        try model.encode(
            text: text,
            task: .retrievalDocument,
            dim: dimension
        )
    }
}
