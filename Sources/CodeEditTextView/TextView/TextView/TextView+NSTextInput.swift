//
//  TextView+NSTextInput.swift
//  
//
//  Created by Khan Winter on 7/16/23.
//

import AppKit

/**
 # Marked Text Notes

 Marked text is used when a character may need more than one keystroke to insert text. For example pressing option-e
 then e again to insert the é character.

 The text view needs to maintain a range of marked text and apply attributes indicating the text is marked. When
 selection is updated, the marked text range can be discarded if the cursor leaves the marked text range.

 ## Notes for multiple cursors

 When inserting using multiple cursors, the marked text should be duplicated across all insertion points. However
 this should only happen if the `setMarkedText` method is called with `NSNotFound` for the replacement range's
 location (indicating that the marked text should appear at the insertion location)

 **Note: Visual studio code Does not correctly support marked text, use Xcode as an example of this behavior.*
 */

extension TextView: NSTextInputClient {
    func insertText(_ string: Any, replacementRange: NSRange) {
        print(string, replacementRange)
    }

    func setMarkedText(_ string: Any, selectedRange: NSRange, replacementRange: NSRange) {

    }

    func unmarkText() {

    }

    func selectedRange() -> NSRange {
        .zero
    }

    func markedRange() -> NSRange {
        .zero
    }

    func hasMarkedText() -> Bool {
        false
    }

    func attributedSubstring(forProposedRange range: NSRange, actualRange: NSRangePointer?) -> NSAttributedString? {
        nil
    }

    func validAttributesForMarkedText() -> [NSAttributedString.Key] {
        []
    }

    func firstRect(forCharacterRange range: NSRange, actualRange: NSRangePointer?) -> NSRect {
        .zero
    }

    func characterIndex(for point: NSPoint) -> Int {
        layoutManager.textOffsetAtPoint(point) ?? NSNotFound
    }
}
