//
//  MinimapView+Draw.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 4/16/25.
//

import AppKit
import CodeEditTextView

public class MinimapContentView: FlippedNSView {
    weak var textView: TextView?
    weak var selectionManager: TextSelectionManager?

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if textView?.isSelectable ?? false {
            selectionManager?.drawSelections(in: dirtyRect)
        }
    }
}
