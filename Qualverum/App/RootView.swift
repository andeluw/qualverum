//
//  RootView.swift
//  Qualverum
//
//  Created by Andrew Wallace on 02/09/26.
//

import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var app
    @Environment(WorkspaceService.self) private var workspace
    @Environment(\.openWindow) private var openWindow
    @AppStorage("developerMode") private var developerMode = false

    var body: some View {
        @Bindable var app = app
        NavigationSplitView {
            SidebarView(developerMode: developerMode)
                .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 300)
        } detail: {
            DetailContainer()
        }
        .searchable(text: $app.searchText, placement: .sidebar, prompt: "Search tenders and evidence")
        .searchSuggestions { GlobalSearchSuggestions() }
        .sheet(isPresented: $app.showNewTender) { NewTenderSheet() }
        .sheet(isPresented: $app.showAddEvidence) { AddEvidenceSheet() }
        .sheet(isPresented: $app.showAnalyze) { AnalyzeSheet() }
        .onChange(of: app.pendingDocument) { _, request in
            guard let request else { return }
            openWindow(id: "pdf", value: request)
            app.pendingDocument = nil
        }
    }
}

private struct DetailContainer: View {
    @Environment(AppState.self) private var app
    @Environment(WorkspaceService.self) private var workspace

    var body: some View {
        @Bindable var app = app
        Group {
            switch app.sidebarSelection ?? .overview {
            case .allTenders: AllTendersView()
            case .overview: OverviewView()
            case .requirements: RequirementsView()
            case .ask: AskView()
            case .companyEvidence: EvidenceView()
            case .tenderDocuments: TenderDocumentsView()
            case .analysisRuns: AnalysisRunsView()
            case .retrievalInspector: RetrievalInspectorView()
            case .chunkInspector: ChunkInspectorView()
            case .experimentInspector: ExperimentInspectorView()
            }
        }
        .inspector(isPresented: Binding(
            get: { app.inspectorPresented && hasInspector },
            set: { app.inspectorPresented = $0 }
        )) {
            InspectorContainer()
                .inspectorColumnWidth(min: 260, ideal: 320, max: 420)
        }
        .toolbar {
            ToolbarItem(placement: .navigation) { TenderSelector() }
            ToolbarItemGroup {
                Button { app.showAnalyze = true } label: {
                    Label("Analyze Tender", systemImage: "play.circle")
                }
                .help("Analyze the current tender")
                .disabled(currentTender == nil)

                if hasInspector {
                    Button { app.inspectorPresented.toggle() } label: {
                        Label("Inspector", systemImage: "sidebar.trailing")
                    }
                    .help("Toggle inspector")
                }
            }
        }
    }

    private var currentTender: Tender? {
        workspace.store.tender(app.activeTenderID)
    }

    private var hasInspector: Bool {
        switch app.sidebarSelection ?? .overview {
        case .retrievalInspector, .experimentInspector: false
        default: true
        }
    }
}

private struct InspectorContainer: View {
    @Environment(AppState.self) private var app

    var body: some View {
        switch app.sidebarSelection ?? .overview {
        case .requirements: RequirementInspector()
        case .companyEvidence: EvidenceInspector()
        case .analysisRuns: AnalysisRunInspector()
        case .ask: AskSourcesInspector()
        case .chunkInspector: ChunkDetailInspector()
        default: OverviewInspector()
        }
    }
}
