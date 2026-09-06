//
//  Chat.swift
//  Qualverum
//
//  Created by Andrew Wallace on 02/09/26.
//

import Foundation

enum ChatScope: String, CaseIterable, Identifiable, Codable, Hashable {
    case currentTender = "Current Tender"
    case selectedRequirement = "Selected Requirement"
    case selectedEvidence = "Selected Evidence"
    case companyLibrary = "Company Evidence Library"
    case allTenders = "All Tenders"

    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .currentTender: "doc.text.magnifyingglass"
        case .selectedRequirement: "checklist"
        case .selectedEvidence: "doc.badge.gearshape"
        case .companyLibrary: "books.vertical"
        case .allTenders: "square.grid.2x2"
        }
    }
}

struct ChatCitation: Identifiable, Codable, Hashable {
    var id = UUID()
    var index: Int              // [1], [2] …
    var label: String           // "School-SIS-Case-Study.pdf · p.4"
    var evidenceID: UUID?
    var documentID: UUID? = nil
    var storedFilename: String? = nil
    
    var page: Int

    // Grabs the file name from the label, the part before " · ".
    var fileName: String? {
        let name = label.split(separator: "·").first?.trimmingCharacters(in: .whitespaces)
        return (name?.isEmpty == false) ? name : nil
    }
}

struct ChatMessage: Identifiable, Codable, Hashable {
    enum Role: String, Codable { case user, assistant }
    enum Kind: String, Codable { case normal, insufficientEvidence, conflicting }
    var id = UUID()
    var role: Role
    var text: String
    var kind: Kind = .normal
    var citations: [ChatCitation] = []
}

struct ChatThread: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var scope: ChatScope
    var tenderID: UUID?
    var messages: [ChatMessage]
}
