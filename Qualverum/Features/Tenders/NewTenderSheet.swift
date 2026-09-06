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
    @Environment(RAGService.self) private var rag

    @State private var name = ""
    @State private var buyer = ""
    @State private var reference = ""
    @State private var deadline = Date.now.addingTimeInterval(60 * 60 * 24 * 30)
    @State private var notes = ""
    @State private var pickedFiles: [URL] = []
    @State private var importing = false

    private let documentImporter = DocumentImportService()

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
                            Text(url.lastPathComponent)
                        }
                    }
                    Button("Add Documents…") { importing = true }
                }
            }
            .formStyle(.grouped)
            .fileImporter(isPresented: $importing, allowedContentTypes: [.pdf], allowsMultipleSelection: true) { result in
                if case .success(let urls) = result {
                    pickedFiles.append(contentsOf: urls)
                }
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

    private func create() {
        let tender = Tender(
            name: name,
            buyer: buyer,
            reference: reference,
            deadline: deadline,
            status: .draft,
            notes: notes,
            created: .now,
            modified: .now,
            versions: [
                .init(
                    label: "1.0",
                    date: .now,
                    change: "Initial",
                    documentCount: 0
                )
            ],
            documents: [],
            requirements: []
        )

        workspace.addTender(tender)
        app.selectTender(tender.id)
        app.sidebarSelection = .overview

        let urls = pickedFiles

        if !urls.isEmpty {
            Task {
                await documentImporter.importAndIndex(
                    urls: urls,
                    tenderID: tender.id,
                    workspace: workspace,
                    rag: rag
                )
            }
        }

        dismiss()
    }
}
