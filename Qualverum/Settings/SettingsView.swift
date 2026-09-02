//
//  SettingsView.swift
//  Qualverum
//
//  Created by Andrew Wallace on 02/09/26.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("developerMode") private var developerMode = false

    var body: some View {
        TabView {
            GeneralSettings().tabItem { Label("General", systemImage: "gear") }
            ModelsSettings().tabItem { Label("Models", systemImage: "cpu") }
            StorageSettings().tabItem { Label("Storage", systemImage: "internaldrive") }
            PrivacySettings().tabItem { Label("Privacy", systemImage: "hand.raised") }
            if developerMode {
                RetrievalSettings().tabItem { Label("Retrieval", systemImage: "slider.horizontal.3") }
            }
            DeveloperSettings().tabItem { Label("Developer", systemImage: "hammer") }
        }
        .frame(width: 480, height: 420)
    }
}

private struct GeneralSettings: View {
    @AppStorage("openLastTender") private var openLastTender = true
    @AppStorage("defaultStartView") private var defaultStartView = "All Tenders"
    @AppStorage("confirmRemoveEvidence") private var confirmRemove = true
    @AppStorage("showStatusCounts") private var showStatusCounts = true
    @AppStorage("showResultsOnFinish") private var showResultsOnFinish = true

    var body: some View {
        Form {
            Toggle("Open Last Tender", isOn: $openLastTender)
            Picker("Default Start View", selection: $defaultStartView) {
                ForEach(["All Tenders", "Overview", "Requirements"], id: \.self) { Text($0) }
            }
            Toggle("Confirm Before Removing Evidence", isOn: $confirmRemove)
            Toggle("Show Status Counts", isOn: $showStatusCounts)
            Toggle("Show Analysis Results on Finish", isOn: $showResultsOnFinish)
        }
        .formStyle(.grouped)
    }
}

private struct ModelsSettings: View {
    var body: some View {
        Form {
            Section("Active Models") {
                LabeledContent("Embedding", value: "Qwen3-Embedding-0.6B")
                LabeledContent("Alternative", value: "EmbeddingGemma 300M")
                LabeledContent("Reranker", value: "Qwen3-Reranker-0.6B")
                LabeledContent("Generator", value: "Apple Foundation Models")
            }
            Section { Text("Model download integration is not available yet.").foregroundStyle(.secondary) }
        }
        .formStyle(.grouped)
    }
}

private struct StorageSettings: View {
    var body: some View {
        Form {
            Section("Workspace Data") {
                LabeledContent("Location", value: "~/Library/Application Support/Qualverum/")
                LabeledContent("Documents", value: "1.2 GB")
                LabeledContent("Vector Index", value: "218 MB")
                LabeledContent("Lexical Index", value: "37 MB")
                LabeledContent("Models", value: "1.4 GB")
                LabeledContent("Cache", value: "182 MB")
            }
            Section {
                Button("Reveal in Finder") {
                    if let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    }
                }
                Button("Clear Cache…") {}
                Button("Change Model Location…") {}
            }
        }
        .formStyle(.grouped)
    }
}

private struct PrivacySettings: View {
    var body: some View {
        Form {
            Section {
                Text("Qualverum is designed for local processing.").font(.headline)
            }
            Section("Planned Architecture") {
                LabeledContent("Tender Documents", value: "On This Mac")
                LabeledContent("Company Evidence", value: "On This Mac")
                LabeledContent("Retrieval Index", value: "On This Mac")
                LabeledContent("Embedding", value: "Local")
                LabeledContent("Reranking", value: "Local")
                LabeledContent("Foundation Models", value: "On-device when available")
            }
        }
        .formStyle(.grouped)
    }
}

private struct RetrievalSettings: View {
    var body: some View {
        Form {
            Section("Chunking") {
                LabeledContent("Strategy", value: "Parent / Child")
                LabeledContent("Child Target", value: "192")
                LabeledContent("Parent Target", value: "600")
            }
            Section("Retrieval") {
                LabeledContent("Embedding", value: "Qwen3")
                LabeledContent("Dimension", value: "512")
                LabeledContent("Dense K", value: "40")
                LabeledContent("BM25 K", value: "40")
                LabeledContent("Fusion", value: "RRF")
                LabeledContent("RRF k", value: "60")
                LabeledContent("Rerank K", value: "20")
                LabeledContent("Final Evidence", value: "5")
                LabeledContent("Context Expansion", value: "Structure Aware")
            }
        }
        .formStyle(.grouped)
    }
}

private struct DeveloperSettings: View {
    @AppStorage("developerMode") private var developerMode = false
    @AppStorage("showChunkIDs") private var showChunkIDs = false
    @AppStorage("showScores") private var showScores = true
    @AppStorage("showTokenCounts") private var showTokenCounts = false
    @AppStorage("showRawContext") private var showRawContext = false
    @AppStorage("mockAnalysisDelay") private var mockDelay = 0.35
    @Environment(AnalysisService.self) private var analysis

    var body: some View {
        Form {
            Toggle("Developer Mode", isOn: $developerMode)
            Section("Inspectors") {
                Text("Developer Mode adds the Retrieval settings tab and the Retrieval, Chunk, and Experiment inspectors in the sidebar.")
                    .foregroundStyle(.secondary).font(.callout)
            }
            Section("Display") {
                Toggle("Show Chunk IDs", isOn: $showChunkIDs)
                Toggle("Show Scores", isOn: $showScores)
                Toggle("Show Token Counts", isOn: $showTokenCounts)
                Toggle("Show Raw Context", isOn: $showRawContext)
            }
            Section("Mock") {
                Slider(value: $mockDelay, in: 0.05...1.0) { Text("Mock Analysis Delay") }
                    .onChange(of: mockDelay) { analysis.mockDelay = mockDelay }
                LabeledContent("Per-step delay", value: String(format: "%.2fs", mockDelay))
            }
        }
        .formStyle(.grouped)
    }
}
