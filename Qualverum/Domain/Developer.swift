//
//  Developer.swift
//  Qualverum
//
//  Created by Andrew Wallace on 02/09/26.
//

import Foundation

struct RetrievalCandidate: Identifiable, Codable, Hashable {
    var id = UUID()
    var chunkID: String
    var document: String
    var page: Int
    var score: Double
    var snippet: String
}

struct RetrievalDebugResult: Identifiable, Codable, Hashable {
    var id = UUID()
    var query: String
    var dense: [RetrievalCandidate]
    var bm25: [RetrievalCandidate]
    var rrf: [RetrievalCandidate]
    var reranked: [RetrievalCandidate]
    var finalContext: [RetrievalCandidate]
}

struct ChunkDebugInfo: Identifiable, Codable, Hashable {
    var id = UUID()
    var chunkID: String
    var parentID: String
    var document: String
    var page: Int
    var section: String
    var chunkType: String
    var tokenCount: Int
    var originalText: String
    var normalizedText: String
    var embeddingInput: String
    var parentContext: String
    var metadata: [String: String]
}

struct ExperimentResult: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var recallAt5: Double
    var recallAt10: Double
    var mrr: Double
    var ndcgAt10: Double
    var p50: Int             // ms
    var p95: Int             // ms
    var memoryMB: Int
}
