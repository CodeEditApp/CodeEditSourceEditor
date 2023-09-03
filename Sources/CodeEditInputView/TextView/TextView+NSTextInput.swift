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

 **Note: Visual studio code Does Not correctly support marked text with multiple cursors,*
 **use Xcode as an example of this behavior.*
 */

/// All documentation in these methods is from the `NSTextInputClient` documentation, copied here for easy of use.
extension TextView: NSTextInputClient {
    // MARK: - Insert Text

    /// Inserts the given string into the receiver, replacing the specified content.
    ///
    /// Programmatic modification of the text is best done by operating on the text storage directly.
    /// Because this method pertains to the actions of the user, the text view must be editable for the
    /// insertion to work.
    ///
    /// - Parameters:
    ///   - string: The text to insert, either an NSString or NSAttributedString instance.
    ///   - replacementRange: The range of content to replace in the receiver’s text storage.
    @objc public func insertText(_ string: Any, replacementRange: NSRange) {
        guard isEditable else { return }

        var insertString: String
        switch string {
        case let string as NSString:
            insertString = string as String
        case let string as NSAttributedString:
            insertString = string.string
        default:
            insertString = ""
            assertionFailure("\(#function) called with invalid string type. Expected String or NSAttributedString.")
        }

        if LineEnding(rawValue: insertString) == .cr && layoutManager.detectedLineEnding == .crlf {
            insertString = LineEnding.crlf.rawValue
        }

        if replacementRange.location == NSNotFound {
            replaceCharacters(in: selectionManager.textSelections.map(\.range), with: insertString)
        } else {
            replaceCharacters(in: replacementRange, with: insertString)
        }
    }

    // MARK: - Marked Text

    /// Replaces a specified range in the receiver’s text storage with the given string and sets the selection.
    ///
    /// If there is no marked text, the current selection is replaced. If there is no selection, the string is
    /// inserted at the insertion point.
    ///
    /// When `string` is an `NSString` object, the receiver is expected to render the marked text with
    /// distinguishing appearance (for example, `NSTextView` renders with `markedTextAttributes`).
    ///
    /// - Parameters:
    ///   - string: The string to insert. Can be either an NSString or NSAttributedString instance.
    ///   - selectedRange: The range to set as the selection, computed from the beginning of the inserted string.
    ///   - replacementRange: The range to replace, computed from the beginning of the marked text.
    @objc public func setMarkedText(_ string: Any, selectedRange: NSRange, replacementRange: NSRange) {
        // TODO: setMarkedText(_ string: Any, selectedRange: NSRange, replacementRange: NSRange)
    }

    /// Unmarks the marked text.
    ///
    /// The receiver removes any marking from pending input text and disposes of the marked text as it wishes.
    /// The text view should accept the marked text as if it had been inserted normally.
    /// If there is no marked text, the invocation of this method has no effect.
    @objc public func unmarkText() {
        // TODO: unmarkText()
    }

    /// Returns the range of selected text.
    /// The returned range measures from the start of the receiver’s text storage, that is, from 0 to the document
    /// length.
    /// - Returns: The range of selected text or {NSNotFound, 0} if there is no selection.
    @objc public func selectedRange() -> NSRange {
        return selectionManager?.textSelections.first?.range ?? NSRange(location: NSNotFound, length: 0)
    }

    /// Returns the range of the marked text.
    ///
    /// The returned range measures from the start of the receiver’s text storage. The return value’s location is
    /// `NSNotFound` and its length is `0` if and only if `hasMarkedText()` returns false.
    ///
    /// - Returns: The range of marked text or {NSNotFound, 0} if there is no marked range.
    @objc public func markedRange() -> NSRange {
        // TODO: markedRange()
        return NSRange(location: NSNotFound, length: 0)
    }

    /// Returns a Boolean value indicating whether the receiver has marked text.
    ///
    /// The text view itself may call this method to determine whether there currently is marked text.
    /// NSTextView, for example, disables the Edit > Copy menu item when this method returns true.
    ///
    /// - Returns: true if the receiver has marked text; otherwise false.
    @objc public func hasMarkedText() -> Bool {
        // TODO: hasMarkedText()
        return false
    }

    /// Returns an array of attribute names recognized by the receiver.
    ///
    /// Returns an empty array if no attributes are supported. See NSAttributedString Application Kit Additions
    /// Reference for the set of string constants representing standard attributes.
    ///
    /// - Returns: An array of NSString objects representing names for the supported attributes.
    @objc public func validAttributesForMarkedText() -> [NSAttributedString.Key] {
        [.underlineStyle, .underlineColor]
    }

    // MARK: - Contents

    /// Returns an attributed string derived from the given range in the receiver's text storage.
    ///
    /// An implementation of this method should be prepared for aRange to be out of bounds.
    /// For example, the InkWell text input service can ask for the contents of the text input client
    /// that extends beyond the document’s range. In this case, you should return the
    /// intersection of the document’s range and aRange. If the location of aRange is completely outside of the
    /// document’s range, return nil.
    ///
    /// - Parameters:
    ///   - range: The range in the text storage from which to create the returned string.
    ///   - actualRange: The actual range of the returned string if it was adjusted, for example, to a grapheme cluster
    ///                  boundary or for performance or other reasons. NULL if range was not adjusted.
    /// - Returns: The string created from the given range. May return nil.
    @objc public func attributedSubstring(
        forProposedRange range: NSRange,
        actualRange: NSRangePointer?
    ) -> NSAttributedString? {
        let realRange = (textStorage.string as NSString).rangeOfComposedCharacterSequences(for: range)
        actualRange?.pointee = realRange
        return textStorage.attributedSubstring(from: realRange)
    }

    /// Returns an attributed string representing the receiver's text storage.
    /// - Returns: The attributed string of the receiver’s text storage.
    @objc public func attributedString() -> NSAttributedString {
        textStorage.attributedSubstring(from: documentRange)
    }

    // MARK: - Positions

    /// Returns the first logical boundary rectangle for characters in the given range.
    /// - Parameters:
    ///   - range: The character range whose boundary rectangle is returned.
    ///   - actualRange: If non-NULL, contains the character range corresponding to the returned area if it was
    ///                  adjusted, for example, to a grapheme cluster boundary or characters in the first line fragment.
    /// - Returns: The boundary rectangle for the given range of characters, in *screen* coordinates.
    ///            The rectangle’s size value can be negative if the text flows to the left.
    @objc public func firstRect(forCharacterRange range: NSRange, actualRange: NSRangePointer?) -> NSRect {
        if actualRange != nil {
            let realRange = (textStorage.string as NSString).rangeOfComposedCharacterSequences(for: range)
            if realRange != range {
                actualRange?.pointee = realRange
            }
        }

        let localRect = (layoutManager.rectForOffset(range.location) ?? .zero)
        let windowRect = convert(localRect, to: nil)
        return window?.convertToScreen(windowRect) ?? .zero
    }

    /// Returns the index of the character whose bounding rectangle includes the given point.
    /// - Parameter point: The point to test, in *screen* coordinates.
    /// - Returns: The character index, measured from the start of the receiver’s text storage, of the character
    ///            containing the given point. Returns NSNotFound if the cursor is not within a character’s
    ///            bounding rectangle.
    @objc public func characterIndex(for point: NSPoint) -> Int {
        guard let windowPoint = window?.convertPoint(fromScreen: point) else {
            return NSNotFound
        }
        let localPoint = convert(windowPoint, from: nil)
        return layoutManager.textOffsetAtPoint(localPoint) ?? NSNotFound
    }

    /// Returns the fraction of the distance from the left side of the character to the right side that a given point
    /// lies.
    ///
    /// For purposes such as dragging out a selection or placing the insertion point, a partial percentage less than or
    /// equal to 0.5 indicates that aPoint should be considered as falling before the glyph; a partial percentage
    /// greater than 0.5 indicates that it should be considered as falling after the glyph. If the nearest glyph doesn’t
    /// lie under aPoint at all (for example, if aPoint is beyond the beginning or end of a line), this ratio is 0 or 1.
    ///
    /// For example, if the glyph stream contains the glyphs “A” and “b”, with the width of “A” being 13 points, and
    /// aPoint is 8 points from the left side of “A”, then the fraction of the distance is 8/13, or 0.615. In this
    /// case, the aPoint should be considered as falling between “A” and “b” for purposes such as dragging out a
    /// selection or placing the insertion point.
    ///
    /// - Parameter point: The point to test.
    /// - Returns: The fraction of the distance aPoint is through the glyph in which it lies. May be 0 or 1 if aPoint
    ///            is not within the bounding rectangle of a glyph (0 if the point is to the left or above the glyph;
    ///            1 if it's to the right or below).
    @objc public func fractionOfDistanceThroughGlyph(for point: NSPoint) -> CGFloat {
        guard let offset = layoutManager.textOffsetAtPoint(point),
              let characterRect = layoutManager.rectForOffset(offset) else { return 0 }
        return (point.x - characterRect.minX)/characterRect.width
    }

    /// Returns the baseline position of a given character relative to the origin of rectangle returned by
    /// `firstRect(forCharacterRange:actualRange:)`.
    /// - Parameter anIndex: Index of the character whose baseline is tested.
    /// - Returns: The vertical distance, in points, between the baseline of the character at anIndex and the rectangle
    ///            origin.
    @objc public func baselineDeltaForCharacter(at anIndex: Int) -> CGFloat {
        // Return the `descent` value from the line fragment at the index
        guard let linePosition = layoutManager.textLineForOffset(anIndex),
              let fragmentPosition = linePosition.data.typesetter.lineFragments.getLine(
                atIndex: anIndex - linePosition.range.location
              ) else {
            return 0
        }
        return fragmentPosition.data.descent
    }
}
