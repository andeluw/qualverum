//
//  ListSearchField.swift
//  Qualverum
//
//  Created by Andrew Wallace on 02/09/26.
//

import SwiftUI

// A compact filter field that lives inside a list screen, so it stays in that pane
// instead of stretching across the window like a toolbar search.
struct ListSearchField: View {
    @Binding var text: String
    var prompt = "Filter"

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField(prompt, text: $text).textFieldStyle(.plain)
            if !text.isEmpty {
                Button { text = "" } label: { Image(systemName: "xmark.circle.fill") }
                    .buttonStyle(.plain).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 5)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
        .frame(maxWidth: 260)
    }
}
