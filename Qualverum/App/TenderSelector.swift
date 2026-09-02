//
//  TenderSelector.swift
//  Qualverum
//
//  Created by Andrew Wallace on 02/09/26.
//

import SwiftUI

struct TenderSelector: View {
    @Environment(AppState.self) private var app
    @Environment(WorkspaceService.self) private var workspace

    private var active: Tender? { workspace.store.tender(app.activeTenderID) }

    var body: some View {
        Menu {
            ForEach(workspace.tenders.filter { $0.status != .archived }) { tender in
                Button {
                    app.selectTender(tender.id)
                } label: {
                    if tender.id == app.activeTenderID {
                        Label(tender.name, systemImage: "checkmark")
                    } else {
                        Text(tender.name)
                    }
                }
            }
            Divider()
            Button("All Tenders") { app.sidebarSelection = .allTenders }
            Button("New Tender…") { app.showNewTender = true }
            Button("Import Tender…") { app.showImportTender = true }
        } label: {
            Label(active?.name ?? "No Tender", systemImage: "folder")
                .labelStyle(.titleAndIcon)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}
