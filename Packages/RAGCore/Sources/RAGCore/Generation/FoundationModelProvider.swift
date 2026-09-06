//
//  FoundationModelProvider.swift
//  RAGCore
//
//  Created by Andrew Wallace on 03/09/26.
//

import FoundationModels

public struct FoundationModelProvider:
    GenerationProvider
{
    private let model: SystemLanguageModel

    public init(
        model:
            SystemLanguageModel = .default
    ) {
        self.model = model
    }

    public var availability: GenerationAvailability {
        switch model.availability {
        case .available:
            return .available

        case .unavailable(
            .appleIntelligenceNotEnabled
        ):
            return .unavailable(
                .appleIntelligenceNotEnabled
            )

        case .unavailable(
            .deviceNotEligible
        ):
            return .unavailable(
                .deviceNotEligible
            )

        case .unavailable(
            .modelNotReady
        ):
            return .unavailable(
                .modelNotReady
            )

        @unknown default:
            return .unavailable(
                .unknown
            )
        }
    }

    public func generate(
        instructions: String,
        prompt: String
    ) async throws -> String {
        switch availability {
        case .available:
            break

        case .unavailable(let reason):
            throw
                GenerationProviderError
                .unavailable(reason)
        }

        // A fresh session prevents old RAG context
        // from accumulating across chat turns.
        let session =
            LanguageModelSession(
                model: model
            ) {
                instructions
            }

        do {
            // Greedy sampling for repeatability: the same question and
            // evidence give the same answer within one model version, which
            // the benchmark and a compliance product both want.
            let response =
                try await session.respond(
                    to: Prompt(prompt),
                    options: GenerationOptions(
                        sampling: .greedy
                    )
                )

            return response.content

        } catch let error
            as LanguageModelSession.GenerationError
        {
            switch error {
            case .exceededContextWindowSize(_):
                throw GenerationProviderError
                    .contextTooLarge

            default:
                throw error
            }
        }
    }
}
