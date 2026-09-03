//
//  GenerationProvider.swift
//  RAGCore
//
//  Created by Andrew Wallace on 03/09/26.
//

public enum GenerationUnavailableReason:
    Sendable,
    Equatable
{
    case appleIntelligenceNotEnabled
    case deviceNotEligible
    case modelNotReady
    case unknown
}

public enum GenerationAvailability:
    Sendable,
    Equatable
{
    case available
    case unavailable(
        GenerationUnavailableReason
    )
}

public enum GenerationProviderError:
    Error,
    Sendable,
    Equatable
{
    case unavailable(
        GenerationUnavailableReason
    )

    case contextTooLarge
}

public protocol GenerationProvider:
    Sendable
{
    var availability: GenerationAvailability
    {
        get
    }

    func generate(
        instructions: String,
        prompt: String
    ) async throws -> String
}
