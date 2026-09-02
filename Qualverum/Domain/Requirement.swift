//
//  Requirement.swift
//  Qualverum
//
//  Created by Andrew Wallace on 02/09/26.
//

import Foundation

enum AssessmentStatus: String, CaseIterable, Identifiable, Codable, Hashable {
    case supported = "Supported"
    case needsReview = "Needs Review"
    case missing = "Missing"
    case notAssessed = "Not Assessed"

    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .supported: "checkmark.circle.fill"
        case .needsReview: "questionmark.circle.fill"
        case .missing: "xmark.circle.fill"
        case .notAssessed: "minus.circle"
        }
    }
}

enum RequirementCategory: String, CaseIterable, Identifiable, Codable, Hashable {
    case eligibility = "Eligibility"
    case technical = "Technical"
    case financial = "Financial"
    case security = "Security"
    case legal = "Legal"
    case experience = "Experience"
    case delivery = "Delivery"
    case compliance = "Compliance"

    var id: String { rawValue }
}

struct RequirementConstraint: Identifiable, Codable, Hashable {
    var id = UUID()
    var label: String
    var detail: String
}

struct ValidationResult: Identifiable, Codable, Hashable {
    var id = UUID()
    var check: String
    var outcome: String
    var status: AssessmentStatus
}

struct RequirementAssessment: Codable, Hashable {
    var status: AssessmentStatus
    var rationale: String
    var evidenceIDs: [UUID]
    var validations: [ValidationResult]
}

struct Requirement: Identifiable, Codable, Hashable {
    var id = UUID()
    var code: String            // like "R17"
    var text: String
    var category: RequirementCategory
    var isMandatory: Bool
    var constraints: [RequirementConstraint] = []
    var assessment: RequirementAssessment
    var sourceDocument: String
    var sourcePage: Int

    var evidenceCount: Int { assessment.evidenceIDs.count }
    var status: AssessmentStatus { assessment.status }
}
