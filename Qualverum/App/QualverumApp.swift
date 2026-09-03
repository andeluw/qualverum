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
    @State private var rag: RAGService
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
        let rag = RAGService()
        _rag = State(initialValue: rag)
        _chat = State(initialValue: ChatService(store: store, rag: rag))

        let defaults = UserDefaults.standard
        let openLast =
            defaults.object(forKey: "openLastTender") as? Bool ?? true
        let lastID = defaults.string(forKey: "lastTenderID").flatMap(UUID.init)
        let activeID: UUID? =
            openLast
            ? (store.tenders.first { $0.id == lastID }?.id
                ?? store.tenders.first?.id)
            : nil
        let state = AppState(activeTenderID: activeID)
        if let name = defaults.string(forKey: "defaultStartView"),
            let start = SidebarItem(rawValue: name)
        {
            state.sidebarSelection = start
        }
        _appState = State(initialValue: state)
    }

    var body: some Scene {
        WindowGroup {
            appRoot
                .environment(store)
                .environment(workspace)
                .environment(evidence)
                .environment(analysis)
                .environment(rag)
                .environment(chat)
                .environment(documents)
                .environment(appState)
                .frame(minWidth: 1100, minHeight: 560)
        }
        .commands {
            QualverumCommands(
                appState: appState,
                analysis: analysis,
                developerMode: $developerMode
            )
        }

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

    #if DEBUG
        private let useDebugRoot = false
    #endif

    @ViewBuilder
    private var appRoot: some View {
        #if DEBUG
            if useDebugRoot {
                DebugRootView()
            } else {
                RootView()
            }
        #else
            RootView()
        #endif
    }
}
