//
//  ChatInputField.swift
//  Qualverum
//
//  Created by Andrew Wallace on 02/09/26.
//

import SwiftUI
import AppKit

// A chat input backed by NSTextView so Return sends, Shift+Return adds a line, and the box
// grows with the text up to maxLines and then scrolls like Xcode's editor.
struct ChatInputField: NSViewRepresentable {
    @Binding var text: String
    @Binding var height: CGFloat
    var placeholder = ""
    var maxLines = 13
    var onSend: () -> Void

    private let font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
    private let inset = NSSize(width: 6, height: 8)

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = PlaceholderTextView()
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.font = font
        textView.drawsBackground = false
        textView.textContainerInset = inset
        textView.isVerticallyResizable = true
        textView.textContainer?.widthTracksTextView = true
        textView.string = text
        textView.placeholder = placeholder
        context.coordinator.textView = textView

        let scroll = NSScrollView()
        scroll.documentView = textView
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.verticalScrollElasticity = .none
        DispatchQueue.main.async { context.coordinator.recalcHeight() }
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        context.coordinator.parent = self
        guard let textView = scroll.documentView as? PlaceholderTextView else { return }
        textView.placeholder = placeholder
        if textView.string != text {
            textView.string = text
            context.coordinator.recalcHeight()
        }
    }

    var minHeight: CGFloat { lineHeight + inset.height * 2 }
    var maxHeight: CGFloat { lineHeight * CGFloat(maxLines) + inset.height * 2 }
    private var lineHeight: CGFloat { ceil(font.ascender - font.descender + font.leading) }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: ChatInputField
        weak var textView: NSTextView?
        init(_ parent: ChatInputField) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            parent.text = textView?.string ?? ""
            textView?.needsDisplay = true
            recalcHeight()
        }

        func textView(_ textView: NSTextView, doCommandBy selector: Selector) -> Bool {
            if selector == #selector(NSResponder.insertNewline(_:)) {
                if NSApp.currentEvent?.modifierFlags.contains(.shift) == true {
                    textView.insertNewlineIgnoringFieldEditor(nil)
                } else {
                    parent.onSend()
                }
                return true
            }
            return false
        }

        func recalcHeight() {
            guard let tv = textView, let lm = tv.layoutManager, let tc = tv.textContainer else { return }
            lm.ensureLayout(for: tc)
            let used = lm.usedRect(for: tc).height + parent.inset.height * 2
            let clamped = min(max(used, parent.minHeight), parent.maxHeight)
            if abs(clamped - parent.height) > 0.5 { parent.height = clamped }
        }
    }
}

// NSTextView has no built-in placeholder, so draw it at the glyph origin where the caret sits.
final class PlaceholderTextView: NSTextView {
    var placeholder = "" { didSet { needsDisplay = true } }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard string.isEmpty, !placeholder.isEmpty else { return }
        let origin = textContainerOrigin
        let point = NSPoint(x: origin.x + (textContainer?.lineFragmentPadding ?? 0), y: origin.y)
        placeholder.draw(at: point, withAttributes: [
            .font: font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize),
            .foregroundColor: NSColor.placeholderTextColor
        ])
    }
}
