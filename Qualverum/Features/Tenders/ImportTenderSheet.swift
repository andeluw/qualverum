//
//  ImportTenderSheet.swift
//  Qualverum
//
//  Created by Andrew Wallace on 02/09/26.
//

import SwiftUI
import UniformTypeIdentifiers

// Documents-first review; New Tender is manual-entry-first.
struct ImportTenderSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var app
    @Environment(WorkspaceService.self) private var workspace
    @Environment(RAGService.self) private var rag

    @State private var pickedFiles: [URL] = []
    @State private var name = ""
    @State private var buyer = ""
    @State private var reference = ""
    @State private var deadline = Date.now.addingTimeInterval(60 * 60 * 24 * 30)
    @State private var importing = false

    private let documentImporter = DocumentImportService()

    var body: some View {
        VStack(spacing: 0) {
            if pickedFiles.isEmpty { chooseStep } else { reviewStep }
        }
        .frame(width: 500, height: 480)
        .fileImporter(isPresented: $importing, allowedContentTypes: [.pdf], allowsMultipleSelection: true) { result in
            if case .success(let urls) = result {
                adopt(urls)
            }
        }
    }

    private var chooseStep: some View {
        ContentUnavailableView {
            Label("Import Tender", systemImage: "square.and.arrow.down")
        } description: {
            Text("Choose the tender documents to import. Qualverum reviews them before creating the tender.")
        } actions: {
            Button("Choose Files…") { importing = true }.keyboardShortcut(.defaultAction)
            Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
        }
    }

    private var reviewStep: some View {
        VStack(spacing: 0) {
            Form {
                Section("Documents") {
                    ForEach(pickedFiles, id: \.self) { url in
                        Text(url.lastPathComponent)
                    }
                    Button("Add More…") { importing = true }
                }
                Section("Tender Details") {
                    TextField("Tender Name", text: $name)
                    TextField("Buyer / Organization", text: $buyer)
                    TextField("Reference Number", text: $reference)
                    DatePicker("Submission Deadline", selection: $deadline, displayedComponents: .date)
                }
            }
            .formStyle(.grouped)

            Divider()
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Import") { performImport() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
        }
    }

    private func adopt(_ urls: [URL]) {
        pickedFiles.append(contentsOf: urls)

        if name.isEmpty, let first = pickedFiles.first {
            name = first.deletingPathExtension().lastPathComponent
                .replacingOccurrences(of: "-", with: " ")
                .replacingOccurrences(of: "_", with: " ")
        }
    }

    private func performImport() {
        let tender = Tender(
            name: name,
            buyer: buyer,
            reference: reference,
            deadline: deadline,
            status: .draft,
            created: .now,
            modified: .now,
            versions: [
                .init(
                    label: "1.0",
                    date: .now,
                    change: "Imported",
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

        Task {
            await documentImporter.importAndIndex(
                urls: urls,
                tenderID: tender.id,
                workspace: workspace,
                rag: rag
            )
        }

        dismiss()
    }
}
