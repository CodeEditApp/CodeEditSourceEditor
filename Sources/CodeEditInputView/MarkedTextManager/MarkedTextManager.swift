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
}
