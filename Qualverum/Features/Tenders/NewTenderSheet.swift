//
//  NewTenderSheet.swift
//  Qualverum
//
//  Created by Andrew Wallace on 02/09/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct NewTenderSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var app
    @Environment(WorkspaceService.self) private var workspace

    @State private var name = ""
    @State private var buyer = ""
    @State private var reference = ""
    @State private var deadline = Date.now.addingTimeInterval(60 * 60 * 24 * 30)
    @State private var notes = ""
    @State private var pickedFiles: [URL] = []
    @State private var importing = false

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Tender") {
                    TextField("Tender Name", text: $name)
                    TextField("Buyer / Organization", text: $buyer)
                    TextField("Reference Number", text: $reference)
                    DatePicker("Submission Deadline", selection: $deadline, displayedComponents: .date)
                }
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical).lineLimit(3, reservesSpace: true)
                }
                Section("Tender Documents") {
                    if pickedFiles.isEmpty {
                        Text("No documents added").foregroundStyle(.secondary)
                    } else {
                        ForEach(pickedFiles, id: \.self) { url in
                            LabeledContent(url.lastPathComponent) {
                                Text("\(mockPages(url)) pages").foregroundStyle(.secondary)
                            }
                        }
                    }
                    Button("Add Documents…") { importing = true }
                }
            }
            .formStyle(.grouped)
            .fileImporter(isPresented: $importing, allowedContentTypes: [.pdf], allowsMultipleSelection: true) { result in
                if case .success(let urls) = result { pickedFiles.append(contentsOf: urls) }
            }

            Divider()
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Create") { create() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
        }
        .frame(width: 480, height: 460)
    }

    // A fake page count, since we don't read the real PDF.
    private func mockPages(_ url: URL) -> Int { 8 + abs(url.lastPathComponent.hashValue % 80) }

    private func create() {
        let docs = pickedFiles.map {
            TenderDocument(name: $0.lastPathComponent, type: "Specification", pages: mockPages($0),
                           version: "1.0", imported: .now, state: .imported, sampleResource: nil)
        }
        let tender = Tender(
            name: name, buyer: buyer, reference: reference, deadline: deadline,
            status: pickedFiles.isEmpty ? .draft : .imported, notes: notes,
            created: .now, modified: .now,
            versions: [.init(label: "1.0", date: .now, change: "Initial", documentCount: docs.count)],
            documents: docs, requirements: [])
        workspace.addTender(tender)
        app.activeTenderID = tender.id
        app.sidebarSelection = .overview
        dismiss()
    }
}
