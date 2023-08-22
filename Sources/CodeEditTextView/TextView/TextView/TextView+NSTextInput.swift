//
//  TextView+NSTextInput.swift
//  
//
//  Created by Khan Winter on 7/16/23.
//

import AppKit
import TextStory

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
    @objc public func insertText(_ string: Any, replacementRange: NSRange) {
        guard isEditable else { return }
        textStorage.beginEditing()
        selectionManager?.textSelections.forEach { selection in
            switch string {
            case let string as NSString:
                textStorage.replaceCharacters(in: selection.range, with: string as String)
                selection.didInsertText(length: string.length)
                _undoManager?.registerMutation(
                    TextMutation(string: string as String, range: selection.range, limit: textStorage.length)
                )
            case let string as NSAttributedString:
                textStorage.replaceCharacters(in: selection.range, with: string)
                selection.didInsertText(length: string.length)
                _undoManager?.registerMutation(
                    TextMutation(string: string.string, range: selection.range, limit: textStorage.length)
                )
            default:
                assertionFailure("\(#function) called with invalid string type. Expected String or NSAttributedString.")
            }
        }
        textStorage.endEditing()
        selectionManager?.updateSelectionViews()
    }

    @objc public func setMarkedText(_ string: Any, selectedRange: NSRange, replacementRange: NSRange) {

    }

    @objc public func unmarkText() {

    }

    @objc public func selectedRange() -> NSRange {
        return selectionManager?.textSelections.first?.range ?? NSRange.zero
    }

    @objc public func markedRange() -> NSRange {
        .zero
    }

    @objc public func hasMarkedText() -> Bool {
        false
    }

    @objc public func attributedSubstring(
        forProposedRange range: NSRange,
        actualRange: NSRangePointer?
    ) -> NSAttributedString? {
        let realRange = (textStorage.string as NSString).rangeOfComposedCharacterSequences(for: range)
        actualRange?.pointee = realRange
        return textStorage.attributedSubstring(from: realRange)
    }

    @objc public func validAttributesForMarkedText() -> [NSAttributedString.Key] {
        []
    }

    @objc public func firstRect(forCharacterRange range: NSRange, actualRange: NSRangePointer?) -> NSRect {
        print(#function)
        return .zero
    }

    @objc public func characterIndex(for point: NSPoint) -> Int {
        print(#function)
        return layoutManager.textOffsetAtPoint(point) ?? NSNotFound
    }
}
