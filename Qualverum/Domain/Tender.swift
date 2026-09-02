//
//  Tender.swift
//  Qualverum
//
//  Created by Andrew Wallace on 02/09/26.
//

import Foundation

enum TenderStatus: String, CaseIterable, Identifiable, Codable, Hashable {
    case draft = "Draft"
    case imported = "Imported"
    case notAnalyzed = "Not Analyzed"
    case analyzing = "Analyzing"
    case inReview = "In Review"
    case ready = "Ready"
    case submitted = "Submitted"
    case archived = "Archived"

    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .draft: "square.and.pencil"
        case .imported: "tray.and.arrow.down"
        case .notAnalyzed: "circle.dashed"
        case .analyzing: "gearshape.arrow.triangle.2.circlepath"
        case .inReview: "eye"
        case .ready: "checkmark.seal"
        case .submitted: "paperplane"
        case .archived: "archivebox"
        }
    }
}

enum DocumentState: String, CaseIterable, Identifiable, Codable, Hashable {
    case imported = "Imported"
    case parsed = "Parsed"
    case indexed = "Indexed"
    case unavailable = "Unavailable"

    var id: String { rawValue }
}

struct TenderVersion: Identifiable, Codable, Hashable {
    var id = UUID()
    var label: String
    var date: Date
    var change: String
    var documentCount: Int
}

struct TenderDocument: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var type: String
    var pages: Int
    var version: String
    var imported: Date
    var state: DocumentState
    var sampleResource: String?   // name of a sample PDF, if we have one
}

struct Tender: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var buyer: String
    var reference: String
    var deadline: Date
    var status: TenderStatus
    var notes: String = ""
    var created: Date
    var modified: Date
    var versions: [TenderVersion]
    var documents: [TenderDocument]
    var requirements: [Requirement]

    var currentVersion: String { versions.first?.label ?? "1.0" }

    var supportedCount: Int { requirements.filter { $0.status == .supported }.count }
    var needsReviewCount: Int { requirements.filter { $0.status == .needsReview }.count }
    var missingCount: Int { requirements.filter { $0.status == .missing }.count }
    var requirementCount: Int { requirements.count }

    var readiness: Double {   // 0 to 1, the share that are Supported
        guard requirementCount > 0 else { return 0 }
        return Double(supportedCount) / Double(requirementCount)
    }
}
