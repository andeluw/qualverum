//
//  Commands.swift
//  Qualverum
//
//  Created by Andrew Wallace on 02/09/26.
//

import SwiftUI

struct QualverumCommands: Commands {
    @Bindable var appState: AppState
    let analysis: AnalysisService
    @Binding var developerMode: Bool

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("New Tender…") { appState.showNewTender = true }
                .keyboardShortcut("n", modifiers: [.command])
            Button("Import Tender…") { appState.showImportTender = true }
                .keyboardShortcut("i", modifiers: [.command, .shift])
            Button("Add Evidence…") { appState.showAddEvidence = true }
                .keyboardShortcut("e", modifiers: [.command, .shift])
        }

        CommandMenu("Analysis") {
            Button("Analyze Tender") { appState.showAnalyze = true }
                .keyboardShortcut("r", modifiers: [.command])
            Button("Cancel Analysis") { analysis.cancel() }
                .disabled(analysis.status != .running)
        }

        CommandGroup(after: .sidebar) {
            Button("Show Inspector") { appState.inspectorPresented.toggle() }
                .keyboardShortcut("i", modifiers: [.command, .option])
            Divider()
            Button("All Tenders") { appState.sidebarSelection = .allTenders }
                .keyboardShortcut("1", modifiers: .command)
            Button("Overview") { appState.sidebarSelection = .overview }
                .keyboardShortcut("2", modifiers: .command)
            Button("Requirements") { appState.sidebarSelection = .requirements }
                .keyboardShortcut("3", modifiers: .command)
            Button("Ask Qualverum") { appState.sidebarSelection = .ask }
                .keyboardShortcut("4", modifiers: .command)
            Button("Company Evidence") { appState.sidebarSelection = .companyEvidence }
                .keyboardShortcut("5", modifiers: .command)
            Divider()
            Toggle("Developer Mode", isOn: $developerMode)
        }
    }
}
