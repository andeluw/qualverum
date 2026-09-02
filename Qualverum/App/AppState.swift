//
//  AppState.swift
//  Qualverum
//
//  Created by Andrew Wallace on 02/09/26.
//

import SwiftUI
import Observation

enum SidebarItem: String, CaseIterable, Identifiable, Hashable {
    case allTenders = "All Tenders"
    case overview = "Overview"
    case requirements = "Requirements"
    case ask = "Ask Qualverum"
    case companyEvidence = "Company Evidence"
    case tenderDocuments = "Tender Documents"
    case analysisRuns = "Analysis History"
    case retrievalInspector = "Retrieval Inspector"
    case chunkInspector = "Chunk Inspector"
    case experimentInspector = "Experiment Inspector"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .allTenders: "square.grid.2x2"
        case .overview: "chart.bar.doc.horizontal"
        case .requirements: "checklist"
        case .ask: "bubble.left.and.text.bubble.right"
        case .companyEvidence: "books.vertical"
        case .tenderDocuments: "doc.on.doc"
        case .analysisRuns: "clock.arrow.circlepath"
        case .retrievalInspector: "magnifyingglass.circle"
        case .chunkInspector: "square.stack.3d.up"
        case .experimentInspector: "testtube.2"
        }
    }

    var isDeveloper: Bool {
        switch self {
        case .retrievalInspector, .chunkInspector, .experimentInspector: true
        default: false
        }
    }
}

@Observable final class AppState {
    var activeTenderID: UUID?
    var sidebarSelection: SidebarItem? = .overview

    var selectedRequirementID: UUID?
    var selectedEvidenceID: UUID?
    var selectedAnalysisRunID: UUID?
    var selectedChatThreadID: UUID?
    var selectedChunkID: UUID?
    var selectedDocumentID: UUID?

    var inspectorPresented = true
    var searchText = ""

    var showNewTender = false
    var showImportTender = false
    var showAddEvidence = false
    var showAnalyze = false

    // Set this to open the PDF window, which RootView watches for.
    var pendingDocument: PDFRequest?

    init(activeTenderID: UUID?) {
        self.activeTenderID = activeTenderID
    }

    var askPreset: (scope: ChatScope, seed: String)?

    func askAbout(scope: ChatScope, seed: String) {
        askPreset = (scope, seed)
        sidebarSelection = .ask
    }

    // Drop the old tender's selections; shared evidence selection stays.
    func selectTender(_ id: UUID?) {
        activeTenderID = id
        selectedRequirementID = nil
        selectedAnalysisRunID = nil
        selectedChatThreadID = nil
    }

    func selectThread(_ thread: ChatThread) {
        selectedChatThreadID = thread.id
        if let tenderID = thread.tenderID { activeTenderID = tenderID }
    }
}

struct PDFRequest: Identifiable, Hashable, Codable {
    var id = UUID()
    var title: String
    var resource: String?
    var page: Int
}
