//
//  Analysis.swift
//  Qualverum
//
//  Created by Andrew Wallace on 02/09/26.
//

import Foundation
import RAGCore

enum AnalysisStatus: String, CaseIterable, Identifiable, Codable, Hashable {
    case idle = "Idle"
    case running = "Running"
    case completed = "Completed"
    case cancelled = "Cancelled"
    case failed = "Failed"

    var id: String { rawValue }
}

struct AnalysisConfiguration: Codable, Hashable {
    var chunking: String = "Parent / Child"
    var embedding: String = "Qwen3-Embedding-0.6B"
    var dimension: Int = 512
    var denseK: Int = 40
    var bm25K: Int = 40
    var fusion: String = "RRF"
    var rerankK: Int = 20
    var finalEvidence: Int = 5
    var contextExpansion: String = "Structure Aware"
}

struct AnalysisRun: Identifiable, Codable, Hashable {
    var id = UUID()
    var date: Date
    var tenderID: UUID
    var tenderName: String
    var tenderVersion: String
    var evidenceVersion: String
    var configuration: AnalysisConfiguration
    var supported: Int
    var review: Int
    var missing: Int
    var duration: TimeInterval
    var status: AnalysisStatus
}
