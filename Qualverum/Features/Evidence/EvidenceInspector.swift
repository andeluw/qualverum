//
//  EvidenceInspector.swift
//  Qualverum
//
//  Created by Andrew Wallace on 02/09/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct EvidenceInspector: View {
    @Environment(AppState.self) private var app
    @Environment(EvidenceService.self) private var evidenceService

    private var evidence: Evidence? {
        evidenceService.all.first { $0.id == app.selectedEvidenceID }
    }

    var body: some View {
        Group {
            if let e = evidence {
                Form {
                    Section("Metadata") {
                        LabeledContent("Name", value: e.name)
                        LabeledContent("Type", value: e.type.rawValue)
                        LabeledContent("Scope", value: e.scope.rawValue)
                        LabeledContent("Organization", value: e.organization)
                        LabeledContent("Date", value: e.date.short)
                        if let expiry = e.expiry { LabeledContent("Expiry", value: expiry.short) }
                    }
                    Section("Status") {
                        LabeledContent("Status") { EvidenceStatusLabel(status: e.status) }
                    }
                    if !e.facts.isEmpty {
                        Section("Extracted Facts") {
                            ForEach(e.facts) { LabeledContent($0.label, value: $0.value) }
                        }
                    }
                    Section("Used By") {
                        let tenders = evidenceService.usedBy(e)
                        if tenders.isEmpty {
                            Text("Not referenced by any tender yet.").foregroundStyle(.secondary)
                        } else {
                            ForEach(tenders) { t in
                                Button {
                                    app.selectTender(t.id)
                                    app.sidebarSelection = .overview
                                } label: {
                                    Label(t.name, systemImage: "folder")
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    Section("Source File") {
                        LabeledContent("File", value: e.sourceFileName)
                        Button("Open") {
                            app.pendingDocument = PDFRequest(title: e.name, resource: e.sourceFileName, page: e.page)
                        }
                        Button("Ask About Evidence") {
                            app.askAbout(scope: .selectedEvidence, seed: "What does \(e.name) establish?")
                        }
                    }
                }
                .formStyle(.grouped)
            } else {
                ContentUnavailableView("No Evidence Selected", systemImage: "doc.text.magnifyingglass",
                                       description: Text("Select an item to view its facts and reuse."))
            }
        }
    }
}

struct AddEvidenceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(EvidenceService.self) private var evidenceService
    @Environment(AppState.self) private var app

    @State private var fileName = ""
    @State private var scope: EvidenceScope = .shared
    @State private var type: EvidenceType = .certification
    @State private var organization = ""
    @State private var issued = Date.now
    @State private var hasExpiry = false
    @State private var expiry = Date.now.addingTimeInterval(60 * 60 * 24 * 365)
    @State private var notes = ""
    @State private var importing = false

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("File") {
                    LabeledContent("Document", value: fileName.isEmpty ? "None selected" : fileName)
                    Button("Choose File…") { importing = true }
                }
                Section("Metadata") {
                    Picker("Scope", selection: $scope) { ForEach(EvidenceScope.allCases) { Text($0.rawValue).tag($0) } }
                    Picker("Type", selection: $type) { ForEach(EvidenceType.allCases) { Text($0.rawValue).tag($0) } }
                    TextField("Organization", text: $organization)
                    DatePicker("Issued Date", selection: $issued, displayedComponents: .date)
                    Toggle("Has Expiry", isOn: $hasExpiry)
                    if hasExpiry { DatePicker("Expiry", selection: $expiry, displayedComponents: .date) }
                    TextField("Notes", text: $notes, axis: .vertical).lineLimit(2, reservesSpace: true)
                }
            }
            .formStyle(.grouped)
            .fileImporter(isPresented: $importing, allowedContentTypes: [.pdf]) { result in
                if case .success(let url) = result {
                    fileName = url.lastPathComponent
                    if organization.isEmpty { organization = "Meridian Digital Ltd" }
                }
            }

            Divider()
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Add") { add() }.keyboardShortcut(.defaultAction).disabled(fileName.isEmpty)
            }
            .padding()
        }
        .frame(width: 460, height: 440)
    }

    private func add() {
        let e = Evidence(name: (fileName as NSString).deletingPathExtension, type: type, scope: scope,
                         organization: organization, date: issued, expiry: hasExpiry ? expiry : nil,
                         status: .valid, sourceFileName: fileName,
                         tenderID: scope == .tenderSpecific ? app.activeTenderID : nil)
        evidenceService.add(e)
        dismiss()
    }
}
