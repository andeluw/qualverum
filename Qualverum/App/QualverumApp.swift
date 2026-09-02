//
//  QualverumApp.swift
//  Qualverum
//
//  Created by Andrew Wallace on 02/09/26.
//

import SwiftUI

@main
struct QualverumApp: App {
    @State private var store: WorkspaceStore
    @State private var workspace: WorkspaceService
    @State private var evidence: EvidenceService
    @State private var analysis: AnalysisService
    @State private var chat: ChatService
    @State private var documents = DocumentService()
    @State private var appState: AppState

    @AppStorage("developerMode") private var developerMode = false

    init() {
        let store = WorkspaceStore()
        _store = State(initialValue: store)
        _workspace = State(initialValue: WorkspaceService(store: store))
        _evidence = State(initialValue: EvidenceService(store: store))
        _analysis = State(initialValue: AnalysisService(store: store))
        _chat = State(initialValue: ChatService(store: store))
        _appState = State(initialValue: AppState(activeTenderID: store.tenders.first?.id))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(workspace)
                .environment(evidence)
                .environment(analysis)
                .environment(chat)
                .environment(documents)
                .environment(appState)
                .frame(minWidth: 1100, minHeight: 560)
        }
        .commands { QualverumCommands(appState: appState, analysis: analysis, developerMode: $developerMode) }

        Settings {
            SettingsView()
                .environment(store)
                .environment(analysis)
        }

        WindowGroup(id: "pdf", for: PDFRequest.self) { $request in
            PDFViewerView(request: request)
                .environment(documents)
                .frame(minWidth: 520, minHeight: 600)
        }
    }
}
