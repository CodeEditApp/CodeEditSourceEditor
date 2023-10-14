//
//  TextView+ReplaceCharacters.swift
//
//
//  Created by Khan Winter on 9/3/23.
//

import AppKit
import TextStory

extension TextView {
    // MARK: - Replace Characters

    /// Replace the characters in the given ranges with the given string.
    /// - Parameters:
    ///   - ranges: The ranges to replace
    ///   - string: The string to insert in the ranges.
    public func replaceCharacters(in ranges: [NSRange], with string: String) {
        guard isEditable else { return }
        layoutManager.beginTransaction()
        textStorage.beginEditing()
        // Can't insert an empty string into an empty range. One must be not empty
        for range in ranges where
        (delegate?.textView(self, shouldReplaceContentsIn: range, with: string) ?? true)
        && (!range.isEmpty || !string.isEmpty) {
            delegate?.textView(self, willReplaceContentsIn: range, with: string)

            layoutManager.willReplaceCharactersInRange(range: range, with: string)
            _undoManager?.registerMutation(
                TextMutation(string: string as String, range: range, limit: textStorage.length)
            )
            textStorage.replaceCharacters(
                in: range,
                with: NSAttributedString(string: string, attributes: typingAttributes)
            )

            delegate?.textView(self, didReplaceContentsIn: range, with: string)
        }
        layoutManager.endTransaction()
        textStorage.endEditing()
    }

    /// Replace the characters in a range with a new string.
    /// - Parameters:
    ///   - range: The range to replace.
    ///   - string: The string to insert in the range.
    public func replaceCharacters(in range: NSRange, with string: String) {
        replaceCharacters(in: [range], with: string)
    }
}
