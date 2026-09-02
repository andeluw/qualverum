//
//  RequirementInspector.swift
//  Qualverum
//
//  Created by Andrew Wallace on 02/09/26.
//

import SwiftUI

struct RequirementInspector: View {
    @Environment(AppState.self) private var app
    @Environment(WorkspaceService.self) private var workspace

    private var requirement: Requirement? {
        guard let t = workspace.store.tender(app.activeTenderID) else { return nil }
        return t.requirements.first { $0.id == app.selectedRequirementID }
    }

    var body: some View {
        Group {
            if let r = requirement {
                Form {
                    Section("Requirement") {
                        LabeledContent("ID", value: r.code)
                        Text(r.text)
                        LabeledContent("Mandatory", value: r.isMandatory ? "Required" : "Optional")
                    }
                    Section("Classification") {
                        LabeledContent("Category", value: r.category.rawValue)
                    }
                    if !r.constraints.isEmpty {
                        Section("Constraints") {
                            ForEach(r.constraints) { LabeledContent($0.label, value: $0.detail) }
                        }
                    }
                    Section("Assessment") {
                        LabeledContent("Status") { AssessmentStatusLabel(status: r.status) }
                        Text(r.assessment.rationale).font(.callout).foregroundStyle(.secondary)
                    }
                    if !r.assessment.evidenceIDs.isEmpty {
                        Section("Evidence") {
                            ForEach(r.assessment.evidenceIDs, id: \.self) { id in
                                if let e = workspace.store.evidence(id) {
                                    Button {
                                        app.pendingDocument = PDFRequest(title: e.name, resource: e.sourceFileName, page: e.page)
                                    } label: {
                                        HStack {
                                            EvidenceStatusLabel(status: e.status).labelStyle(.iconOnly)
                                            Text(e.name)
                                            Spacer()
                                            Image(systemName: "arrow.up.right.square").foregroundStyle(.secondary)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    if !r.assessment.validations.isEmpty {
                        Section("Validation") {
                            ForEach(r.assessment.validations) { v in
                                LabeledContent(v.check) {
                                    Label(v.outcome, systemImage: v.status.symbol)
                                        .labelStyle(.titleAndIcon)
                                }
                            }
                        }
                    }
                    Section("Source") {
                        LabeledContent("Document", value: r.sourceDocument)
                        LabeledContent("Page", value: "\(r.sourcePage)")
                    }
                    Section {
                        Button("Open Source") {
                            app.pendingDocument = PDFRequest(title: r.sourceDocument, resource: r.sourceDocument, page: r.sourcePage)
                        }
                        Button("Ask About Requirement") {
                            app.askAbout(scope: .selectedRequirement, seed: "Why is \(r.code) \(r.status.rawValue)?")
                        }
                    }
                }
                .formStyle(.grouped)
            } else {
                ContentUnavailableView("No Requirement Selected", systemImage: "checklist",
                                       description: Text("Select a requirement to see its assessment."))
            }
        }
    }
}
