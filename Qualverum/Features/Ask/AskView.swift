//
//  AskView.swift
//  Qualverum
//
//  Created by Andrew Wallace on 02/09/26.
//

import SwiftUI

struct AskView: View {
    @Environment(AppState.self) private var app
    @Environment(ChatService.self) private var chat
    @Environment(WorkspaceService.self) private var workspace

    @State private var scope: ChatScope = .currentTender
    @State private var draft = ""
    @State private var inputHeight: CGFloat = 36
    @State private var renaming: ChatThread?
    @State private var renameText = ""

    private var thread: ChatThread? {
        chat.threads.first { $0.id == app.selectedChatThreadID }
    }

    var body: some View {
        // Just the conversation. History lives in the toolbar and sources in the window inspector,
        // so Ask keeps the same three panes as every other screen instead of adding a fourth.
        conversation
            .navigationTitle("Ask Qualverum")
            .toolbar { historyMenu }
            .onAppear(perform: applyPreset)
            .onChange(of: app.askPreset?.seed) { applyPreset() }
            .onChange(of: scope) { _, newScope in
                if let thread { chat.setScope(newScope, for: thread.id) }
            }
            .alert(
                "Rename Chat",
                isPresented: .init(
                    get: { renaming != nil },
                    set: { if !$0 { renaming = nil } }
                )
            ) {
                TextField("Title", text: $renameText)
                Button("Rename") {
                    if let t = renaming { chat.rename(t.id, to: renameText) }
                    renaming = nil
                }
                Button("Cancel", role: .cancel) { renaming = nil }
            }
    }

    @ToolbarContentBuilder
    private var historyMenu: some ToolbarContent {
        ToolbarItem {
            Menu {
                Button {
                    newChat()
                } label: {
                    Label("New Chat", systemImage: "square.and.pencil")
                }
                if let thread {
                    Button("Rename…") { rename(thread) }
                    Button("Delete", role: .destructive) {
                        chat.delete(thread.id)
                    }
                }
                if !chat.threads.isEmpty {
                    Divider()
                    Section("History") {
                        ForEach(chat.threads) { t in
                            Button {
                                app.selectThread(t)
                                scope = t.scope
                            } label: {
                                Label(
                                    t.title,
                                    systemImage: t.id == thread?.id
                                        ? "checkmark" : t.scope.symbol
                                )
                            }
                        }
                    }
                }
            } label: {
                Label("Chats", systemImage: "clock.arrow.circlepath")
            }
        }
    }

    private var conversation: some View {
        VStack(spacing: 0) {
            scopeBar
            Divider()
            contentArea
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider()
            composer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var contentArea: some View {
        if let thread {
            if thread.messages.isEmpty {
                suggestions
            } else {
                messageList(thread)
            }
        } else {
            ContentUnavailableView {
                Label(
                    "Ask Qualverum",
                    systemImage: "bubble.left.and.text.bubble.right"
                )
            } description: {
                Text(
                    "Ask grounded questions about requirements, evidence, and readiness."
                )
            } actions: {
                Button("New Chat") { newChat() }
            }
        }
    }

    private var scopeBar: some View {
        HStack {
            Picker("Scope", selection: $scope) {
                ForEach(ChatScope.allCases) {
                    Label($0.rawValue, systemImage: $0.symbol).tag($0)
                }
            }
            .pickerStyle(.menu)
            .fixedSize()
            Spacer()
            if chat.pendingThreadID == thread?.id {
                ProgressView().controlSize(.small)
                Text("Answering…").foregroundStyle(.secondary).font(.callout)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // Keeps content readable on wide windows and lets it shrink on narrow ones.
    private let contentMaxWidth: CGFloat = 780

    private var suggestions: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Suggested questions").font(.headline).padding(.bottom, 4)
                ForEach(Self.suggested, id: \.self) { q in
                    Button {
                        draft = q
                    } label: {
                        Label(q, systemImage: "text.bubble").frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )
                    }
                    .buttonStyle(.bordered)
                }
            }
            .frame(maxWidth: contentMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
            .padding()
        }
    }

    private func messageList(_ thread: ChatThread) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(thread.messages) { MessageRow(message: $0) }
            }
            .frame(maxWidth: contentMaxWidth)
            .frame(maxWidth: .infinity)
            .padding()
        }
    }

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespaces).isEmpty
            && chat.pendingThreadID != thread?.id
    }

    private var composer: some View {
        ChatInputField(
            text: $draft,
            height: $inputHeight,
            placeholder: "Ask a question…",
            onSend: sendDraft
        )
        .frame(height: inputHeight)
        .padding(.trailing, 34)  // leave room for the send button
        .padding(.horizontal, 4).padding(.vertical, 2)
        .background(
            .background.secondary,
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.separator))
        .overlay(alignment: .bottomTrailing) {
            Button {
                sendDraft()
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(Color.accentColor, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Send")
            .disabled(!canSend)
            .padding(6)
        }
        .frame(maxWidth: contentMaxWidth)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: actions

    private func sendDraft() {
        let text = draft.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        let id: UUID
        if let thread { id = thread.id } else { id = newChat() }
        chat.send(text, to: id)
        draft = ""
    }

    @discardableResult
    private func newChat() -> UUID {
        let t = chat.newThread(scope: scope, tenderID: app.activeTenderID)
        app.selectedChatThreadID = t.id
        return t.id
    }

    private func rename(_ t: ChatThread) {
        renameText = t.title
        renaming = t
    }

    private func applyPreset() {
        guard let preset = app.askPreset else { return }
        scope = preset.scope
        draft = preset.seed
        app.askPreset = nil
    }

    static let suggested = [
        "What is the contract duration?",
        "What are the eligibility requirements?",
        "What documents must the bidder submit?",
        "What is the submission deadline?",
        "What are the technical requirements?",
        "Are there any mandatory certifications?",
    ]
}

private struct MessageRow: View {
    let message: ChatMessage
    @Environment(AppState.self) private var app
    @Environment(EvidenceService.self) private var evidenceService

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .top) {
            if isUser { Spacer(minLength: 48) }
            bubble
            if !isUser { Spacer(minLength: 48) }
        }
    }

    private var bubble: some View {
        VStack(alignment: .leading, spacing: 8) {
            if message.kind == .insufficientEvidence {
                Label(
                    "Insufficient evidence",
                    systemImage: "exclamationmark.triangle"
                )
                .font(.caption).foregroundStyle(.orange)
            }
            Text(message.text)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
            if !message.citations.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(message.citations) { c in
                        Button {
                            app.pendingDocument = PDFRequest(
                                title: c.label,
                                resource: c.fileName,
                                storedFilename: c.storedFilename,
                                page: c.page
                            )
                        } label: {
                            Text("[\(c.index)] \(c.label)").font(.caption)
                                .monospaced()
                        }
                        .buttonStyle(.link)
                    }
                }
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(
            isUser
                ? AnyShapeStyle(Color.accentColor.opacity(0.15))
                : AnyShapeStyle(.background.secondary),
            in: RoundedRectangle(cornerRadius: 14)
        )
    }
}

struct AskSourcesInspector: View {
    @Environment(AppState.self) private var app
    @Environment(ChatService.self) private var chat

    private var citations: [ChatCitation] {
        chat.threads.first { $0.id == app.selectedChatThreadID }?
            .messages.flatMap(\.citations) ?? []
    }

    var body: some View {
        if citations.isEmpty {
            ContentUnavailableView(
                "No Sources",
                systemImage: "doc.text.magnifyingglass",
                description: Text("Cited sources appear here.")
            )
        } else {
            List {
                Section("Sources") {
                    ForEach(citations) { c in
                        Button {
                            app.pendingDocument = PDFRequest(
                                title: c.label,
                                resource: c.fileName,
                                storedFilename: c.storedFilename,
                                page: c.page
                            )
                        } label: {
                            Label("\(c.label)", systemImage: "doc.richtext")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
