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
    @objc public func insertText(_ string: Any, replacementRange: NSRange) {
        guard isEditable else { return }
        textStorage.beginEditing()
        selectionManager?.textSelections.forEach { selection in
            switch string {
            case let string as NSString:
                textStorage.replaceCharacters(in: selection.range, with: string as String)
                selection.didInsertText(length: string.length)
            case let string as NSAttributedString:
                textStorage.replaceCharacters(in: selection.range, with: string)
                selection.didInsertText(length: string.length)
            default:
                assertionFailure("\(#function) called with invalid string type. Expected String or NSAttributedString.")
            }
        }
        textStorage.endEditing()
        selectionManager?.updateSelectionViews()
        print(selectionManager!.textSelections.map { $0.range })
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
        print(realRange)
        return textStorage.attributedSubstring(from: realRange)
    }

    @objc public func validAttributesForMarkedText() -> [NSAttributedString.Key] {
        []
    }

    @objc public func firstRect(forCharacterRange range: NSRange, actualRange: NSRangePointer?) -> NSRect {
        .zero
    }

    @objc public func characterIndex(for point: NSPoint) -> Int {
        layoutManager.textOffsetAtPoint(point) ?? NSNotFound
    }
}
