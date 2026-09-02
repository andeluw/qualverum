//
//  GlobalSearch.swift
//  Qualverum
//
//  Created by Andrew Wallace on 02/09/26.
//

import SwiftUI

struct GlobalSearchSuggestions: View {
    @Environment(AppState.self) private var app
    @Environment(WorkspaceService.self) private var workspace
    @Environment(EvidenceService.self) private var evidenceService

    private var query: String { app.searchText.trimmingCharacters(in: .whitespaces).lowercased() }

    private var tenders: [Tender] {
        workspace.tenders.filter { $0.name.lowercased().contains(query) || $0.buyer.lowercased().contains(query) }
    }
    // Only searches requirements in the current tender, while evidence and tenders cover everything.
    private var requirements: [(Tender, Requirement)] {
        guard let t = workspace.store.tender(app.activeTenderID) else { return [] }
        return t.requirements.filter { $0.text.lowercased().contains(query) || $0.code.lowercased().contains(query) }
            .map { (t, $0) }
    }
    private var evidence: [Evidence] {
        evidenceService.all.filter { $0.name.lowercased().contains(query) || $0.organization.lowercased().contains(query) }
    }
    private var documents: [(Tender, TenderDocument)] {
        workspace.tenders.flatMap { t in
            t.documents.filter { $0.name.lowercased().contains(query) }.map { (t, $0) }
        }
    }

    var body: some View {
        if !query.isEmpty {
            if !tenders.isEmpty {
                Section("Tenders") {
                    ForEach(tenders.prefix(5)) { t in
                        Button { openTender(t) } label: { Label(t.name, systemImage: "folder") }
                    }
                }
            }
            if !requirements.isEmpty {
                Section("Requirements") {
                    ForEach(requirements.prefix(5), id: \.1.id) { _, r in
                        Button { openRequirement(r) } label: {
                            Label("\(r.code), \(r.text)", systemImage: "checklist")
                        }
                    }
                }
            }
            if !evidence.isEmpty {
                Section("Evidence") {
                    ForEach(evidence.prefix(5)) { e in
                        Button { openEvidence(e) } label: { Label(e.name, systemImage: "doc.text") }
                    }
                }
            }
            if !documents.isEmpty {
                Section("Tender Documents") {
                    ForEach(documents.prefix(5), id: \.1.id) { t, d in
                        Button { openDocument(t) } label: { Label(d.name, systemImage: "doc.on.doc") }
                    }
                }
            }
        }
    }

    private func clear() { app.searchText = "" }

    private func openTender(_ t: Tender) { app.activeTenderID = t.id; app.sidebarSelection = .overview; clear() }
    private func openRequirement(_ r: Requirement) { app.selectedRequirementID = r.id; app.sidebarSelection = .requirements; clear() }
    private func openEvidence(_ e: Evidence) { app.selectedEvidenceID = e.id; app.sidebarSelection = .companyEvidence; clear() }
    private func openDocument(_ t: Tender) { app.activeTenderID = t.id; app.sidebarSelection = .tenderDocuments; clear() }
}
