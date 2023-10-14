//
//  TextView+Accessibility.swift
//
//
//  Created by Khan Winter on 10/14/23.
//

import AppKit

extension TextView {
    override open func isAccessibilityElement() -> Bool {
        true
    }

    override open func isAccessibilityEnabled() -> Bool {
        true
    }

    override open func isAccessibilityFocused() -> Bool {
        isFirstResponder
    }

    override open func accessibilityLabel() -> String? {
        "Text Editor"
    }

    override open func accessibilityRole() -> NSAccessibility.Role? {
        .textArea
    }

    override open func accessibilityValue() -> Any? {
        string
    }

    override open func setAccessibilityValue(_ accessibilityValue: Any?) {
        guard let string = accessibilityValue as? String else {
            return
        }

        self.string = string
    }

    override open func accessibilityString(for range: NSRange) -> String? {
        textStorage.substring(
            from: textStorage.mutableString.rangeOfComposedCharacterSequences(for: range)
        )
    }

    // MARK: Selections

    override open func accessibilitySelectedText() -> String? {
        guard let selection = selectionManager
            .textSelections
            .sorted(by: { $0.range.lowerBound < $1.range.lowerBound })
            .first else {
            return nil
        }
        let range = (textStorage.string as NSString).rangeOfComposedCharacterSequences(for: selection.range)
        return textStorage.substring(from: range)
    }

    override open func accessibilitySelectedTextRange() -> NSRange {
        guard let selection = selectionManager
            .textSelections
            .sorted(by: { $0.range.lowerBound < $1.range.lowerBound })
            .first else {
            return .zero
        }
        return textStorage.mutableString.rangeOfComposedCharacterSequences(for: selection.range)
    }

    override open func accessibilitySelectedTextRanges() -> [NSValue]? {
        selectionManager.textSelections.map { selection in
            textStorage.mutableString.rangeOfComposedCharacterSequences(for: selection.range) as NSValue
        }
    }

    override open func accessibilityInsertionPointLineNumber() -> Int {
        guard let selection = selectionManager
            .textSelections
            .sorted(by: { $0.range.lowerBound < $1.range.lowerBound })
            .first,
              let linePosition = layoutManager.textLineForOffset(selection.range.location) else {
            return 0
        }
        return linePosition.index
    }

    override open func setAccessibilitySelectedTextRange(_ accessibilitySelectedTextRange: NSRange) {
        selectionManager.setSelectedRange(accessibilitySelectedTextRange)
    }

    override open func setAccessibilitySelectedTextRanges(_ accessibilitySelectedTextRanges: [NSValue]?) {
        let ranges = accessibilitySelectedTextRanges?.compactMap { $0 as? NSRange } ?? []
        selectionManager.setSelectedRanges(ranges)
    }

    // MARK: Text Ranges

    override open func accessibilityNumberOfCharacters() -> Int {
        string.count
    }

    override open func accessibilityRange(forLine line: Int) -> NSRange {
        guard line >= 0 && layoutManager.lineStorage.count > line,
              let linePosition = layoutManager.textLineForIndex(line) else {
            return .zero
        }
        return linePosition.range
    }

    override open func accessibilityRange(for point: NSPoint) -> NSRange {
        guard let location = layoutManager.textOffsetAtPoint(point) else { return .zero }
        return NSRange(location: location, length: 0)
    }

    override open func accessibilityRange(for index: Int) -> NSRange {
        textStorage.mutableString.rangeOfComposedCharacterSequence(at: index)
    }
}
