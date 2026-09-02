//
//  Evidence.swift
//  Qualverum
//
//  Created by Andrew Wallace on 02/09/26.
//

import Foundation

enum EvidenceStatus: String, CaseIterable, Identifiable, Codable, Hashable {
    case valid = "Valid"
    case expiringSoon = "Expiring Soon"
    case expired = "Expired"
    case needsReview = "Needs Review"

    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .valid: "checkmark.circle.fill"
        case .expiringSoon: "clock.badge.exclamationmark"
        case .expired: "xmark.octagon.fill"
        case .needsReview: "questionmark.circle.fill"
        }
    }
}

enum EvidenceScope: String, CaseIterable, Identifiable, Codable, Hashable {
    case shared = "Shared Company Evidence"
    case tenderSpecific = "Tender-Specific"

    var id: String { rawValue }
}

enum EvidenceType: String, CaseIterable, Identifiable, Codable, Hashable {
    case certification = "Certification"
    case financialStatement = "Financial Statement"
    case caseStudy = "Case Study"
    case projectReference = "Project Reference"
    case securityPolicy = "Security Policy"
    case cv = "CV"
    case license = "License"
    case insurance = "Insurance"
    case corporate = "Corporate Document"
    case clarification = "Clarification Response"
    case declaration = "Declaration"

    var id: String { rawValue }
}

struct EvidenceFact: Identifiable, Codable, Hashable {
    var id = UUID()
    var label: String
    var value: String
}

struct Evidence: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var type: EvidenceType
    var scope: EvidenceScope
    var organization: String
    var date: Date
    var expiry: Date?
    var status: EvidenceStatus
    var facts: [EvidenceFact] = []
    var usedBy: [UUID] = []
    var sourceFileName: String
    var sampleResource: String?
    var page: Int = 1
    var tenderID: UUID?   // owning tender when scope is tenderSpecific
}
