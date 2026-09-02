//
//  SidebarView.swift
//  Qualverum
//
//  Created by Andrew Wallace on 02/09/26.
//

import SwiftUI

struct SidebarView: View {
    let developerMode: Bool
    @Environment(AppState.self) private var app

    var body: some View {
        @Bindable var app = app
        List(selection: $app.sidebarSelection) {
            Section("Workspace") {
                row(.overview)
                row(.requirements)
                row(.ask)
            }
            Section("Library") {
                row(.companyEvidence)
                row(.tenderDocuments)
            }
            Section("Activity") {
                row(.analysisRuns)
                row(.allTenders)
            }
            if developerMode {
                Section("Developer") {
                    row(.retrievalInspector)
                    row(.chunkInspector)
                    row(.experimentInspector)
                }
            }
        }
        .listStyle(.sidebar)
    }

    private func row(_ item: SidebarItem) -> some View {
        Label(item.rawValue, systemImage: item.symbol).tag(item)
    }
}
