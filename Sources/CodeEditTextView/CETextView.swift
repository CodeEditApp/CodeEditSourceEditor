//
//  CETextView.swift
//  CodeEditTextView
//
//  Created by Khan Winter on 7/8/23.
//

import AppKit
import UniformTypeIdentifiers
import TextStory
import STTextView

class CETextView: STTextView {
    override open func paste(_ sender: Any?) {
        guard let undoManager = undoManager as? CEUndoManager.DelegatedUndoManager else { return }
        undoManager.parent?.beginGrouping()

        let pasteboard = NSPasteboard.general
        if pasteboard.canReadItem(withDataConformingToTypes: [UTType.text.identifier]),
           let string = NSPasteboard.general.string(forType: .string) {
            for textRange in textLayoutManager
                .textSelections
                .flatMap(\.textRanges)
                .sorted(by: { $0.location.compare($1.location) == .orderedDescending }) {
                if let nsRange = textRange.nsRange(using: textContentManager) {
                    undoManager.registerMutation(
                        TextMutation(insert: string, at: nsRange.location, limit: textContentStorage?.length ?? 0)
                    )
                }
                replaceCharacters(in: textRange, with: string)
            }
        }

        undoManager.parent?.endGrouping()
    }
}
