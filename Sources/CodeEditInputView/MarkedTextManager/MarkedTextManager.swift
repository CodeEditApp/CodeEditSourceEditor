//
//  MarkedTextManager.swift
//
//
//  Created by Khan Winter on 11/7/23.
//

import AppKit

/// Manages marked ranges
class MarkedTextManager {
    struct MarkedRanges {
        let ranges: [NSRange]
        let attributes: [NSAttributedString.Key: Any]
    }

    /// All marked ranges being tracked.
    private(set) var markedRanges: [NSRange] = []

    /// The attributes to use for marked text. Defaults to a single underline when `nil`
    var markedTextAttributes: [NSAttributedString.Key: Any]?

    /// True if there is marked text being tracked.
    var hasMarkedText: Bool {
        !markedRanges.isEmpty
    }

    /// Removes all marked ranges.
    func removeAll() {
        markedRanges.removeAll()
    }

    /// Updates the stored marked ranges.
    /// - Parameters:
    ///   - insertLength: The length of the string being inserted.
    ///   - replacementRange: The range to replace with marked text.
    ///   - selectedRange: The selected range from `NSTextInput`.
    ///   - textSelections: The current text selections.
    func updateMarkedRanges(
        insertLength: Int,
        replacementRange: NSRange,
        selectedRange: NSRange,
        textSelections: [TextSelectionManager.TextSelection]
    ) {
        if replacementRange.location == NSNotFound {
            markedRanges = textSelections.map {
                NSRange(location: $0.range.location, length: insertLength)
            }
        } else {
            markedRanges = [selectedRange]
        }
    }

    /// Finds any marked ranges for a line and returns them.
    /// - Parameter lineRange: The range of the line.
    /// - Returns: A `MarkedRange` struct with information about attributes and ranges. `nil` if there is no marked
    ///            text for this line.
    func markedRanges(in lineRange: NSRange) -> MarkedRanges? {
        let attributes = markedTextAttributes ?? [.underlineStyle: NSUnderlineStyle.single.rawValue]
        let ranges = markedRanges.compactMap {
            $0.intersection(lineRange)
        }.map {
            NSRange(location: $0.location - lineRange.location, length: $0.length)
        }
        if ranges.isEmpty {
            return nil
        } else {
            return MarkedRanges(ranges: ranges, attributes: attributes)
        }
    }

    /// Updates marked text ranges for a new set of selections.
    /// - Parameter textSelections: The new text selections.
    /// - Returns: `True` if the marked text needs layout.
    func updateForNewSelections(textSelections: [TextSelectionManager.TextSelection]) -> Bool {
        // Ensure every marked range has a matching selection.
        // If any marked ranges do not have a matching selection, unmark.
        // Matching, in this context, means having a selection in the range location...max
        var markedRanges = markedRanges
        for textSelection in textSelections {
            if let markedRangeIdx = markedRanges.firstIndex(where: {
                ($0.location...$0.max).contains(textSelection.range.location)
                && ($0.location...$0.max).contains(textSelection.range.max)
            }) {
                markedRanges.remove(at: markedRangeIdx)
            } else {
                return true
            }
        }

        // If any remaining marked ranges, we need to unmark.
        if !markedRanges.isEmpty {
            return false
        } else {
            return true
        }
    }
}
