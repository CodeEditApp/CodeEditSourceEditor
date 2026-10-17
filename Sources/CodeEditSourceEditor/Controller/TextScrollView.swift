//
//  TextScrollView.swift
//  CodeEditSourceEditor
//

import AppKit

/// The editor's scroll view. Its content insets pad the text above the first line and below the last, and a click
/// in that padding lands on the scroll view itself, which ignores it. Those clicks go to the text view instead, which
/// places the caret on the nearest line: the first line above the text, the end of the document below it.
final class TextScrollView: NSScrollView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        documentCursor = .iBeam
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let hit = super.hitTest(point)
        guard hit === self, let documentView else { return hit }
        return documentView
    }
}
