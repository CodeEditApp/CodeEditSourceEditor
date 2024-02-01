//
//  Highlighter+NSTextStorageDelegate.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 1/18/24.
//

import AppKit

extension Highlighter: NSTextStorageDelegate {
    /// Processes an edited range in the text.
    /// Will query tree-sitter for any updated indices and re-highlight only the ranges that need it.
    func textStorage(
        _ textStorage: NSTextStorage,
        didProcessEditing editedMask: NSTextStorageEditActions,
        range editedRange: NSRange,
        changeInLength delta: Int
    ) {
        // This method is called whenever attributes are updated, so to avoid re-highlighting the entire document
        // each time an attribute is applied, we check to make sure this is in response to an edit.
        guard editedMask.contains(.editedCharacters) else { return }

        self.storageDidEdit(editedRange: editedRange, delta: delta)
    }

    func textStorage(
        _ textStorage: NSTextStorage,
        willProcessEditing editedMask: NSTextStorageEditActions,
        range editedRange: NSRange,
        changeInLength delta: Int
    ) {
        guard editedMask.contains(.editedCharacters) else { return }

        self.storageWillEdit(editedRange: editedRange)
    }
}
