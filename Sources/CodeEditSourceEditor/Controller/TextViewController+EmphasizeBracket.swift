//
//  TextViewController+EmphasizeBracket.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 4/26/23.
//

import AppKit
import CodeEditTextView

extension TextViewController {
    /// How far from the cursor to scan for a matching bracket, in UTF-16 units. Anchored on the cursor rather than the
    /// visible range, which is empty until the text view's first layout.
    private static let bracketSearchDistance = 4096

    /// Emphasizes bracket pairs using the current selection.
    internal func emphasizeSelectionPairs() {
        guard let bracketPairEmphasis = configuration.appearance.bracketPairEmphasis else { return }
        textView.emphasisManager?.removeEmphases(for: EmphasisGroup.brackets)
        for range in textView.selectionManager.textSelections.map({ $0.range }) {
            if range.isEmpty,
               range.location > 0, // Range is not the beginning of the document
               let precedingCharacter = textView.textStorage.substring(
                from: NSRange(location: range.location - 1, length: 1) // The preceding character exists
               ) {
                for pair in BracketPairs.emphasisValues {
                    if precedingCharacter == pair.0 {
                        // Walk forwards
                        emphasizeForwards(pair, range: range, emphasisType: bracketPairEmphasis)
                    } else if precedingCharacter == pair.1 && range.location - 1 > 0 {
                        // Walk backwards
                        emphasizeBackwards(pair, range: range, emphasisType: bracketPairEmphasis)
                    }
                }
            }
        }
    }

    private func emphasizeForwards(_ pair: (String, String), range: NSRange, emphasisType: BracketPairEmphasis) {
        if let characterIndex = findClosingPair(
            pair.0,
            pair.1,
            from: range.location,
            limit: range.location + Self.bracketSearchDistance,
            reverse: false
        ) {
            emphasizeCharacter(characterIndex)
            if emphasisType.emphasizesSourceBracket {
                emphasizeCharacter(range.location - 1)
            }
        }
    }

    private func emphasizeBackwards(_ pair: (String, String), range: NSRange, emphasisType: BracketPairEmphasis) {
        if let characterIndex = findClosingPair(
            pair.1,
            pair.0,
            from: range.location - 1,
            limit: range.location - Self.bracketSearchDistance,
            reverse: true
        ) {
            emphasizeCharacter(characterIndex)
            if emphasisType.emphasizesSourceBracket {
                emphasizeCharacter(range.location - 1)
            }
        }
    }

    /// # Dev Note
    /// It's interesting to note that this problem could trivially be turned into a monoid, and the locations of each
    /// pair start/end location determined when the view is loaded. It could then be parallelized for initial speed
    /// and this lookup would be much faster.

    /// Finds a closing character given a pair of characters, ignores pairs inside the given pair.
    ///
    /// ```pseudocode
    /// { -- Start
    ///   {
    ///   } -- A naive algorithm may find this character as the closing pair, which would be incorrect.
    /// } -- Found
    /// ```
    ///
    /// - Parameters:
    ///   - open: The opening pair to look for.
    ///   - close: The closing pair to look for.
    ///   - from: The index to start from. This should not include the start character. Eg given `"{ }"` looking forward
    ///           the index should be `1`
    ///   - limit: A limiting index to stop at. When `reverse` is `true`, this is the minimum index. When `false` this
    ///            is the maximum index. Clamped to the document.
    ///   - reverse: Set to `true` to walk backwards from `from`.
    /// - Returns: The index of the found closing pair, if any.
    internal func findClosingPair(_ close: String, _ open: String, from: Int, limit: Int, reverse: Bool) -> Int? {
        // Brackets are single UTF-16 units, so the window is scanned as raw code units.
        guard let closeUnit = close.utf16.first, let openUnit = open.utf16.first else { return nil }
        let documentRange = textView.documentRange
        let lowerBound = max(reverse ? limit : from, documentRange.location)
        let upperBound = min(reverse ? from : limit, documentRange.max)
        guard lowerBound < upperBound else { return nil }
        let length = upperBound - lowerBound
        let string = textView.textStorage.string as NSString

        return withUnsafeTemporaryAllocation(of: unichar.self, capacity: length) { buffer -> Int? in
            guard let units = buffer.baseAddress else { return nil }
            string.getCharacters(units, range: NSRange(location: lowerBound, length: length))
            // Count each close. The open that takes the count below zero is the match.
            var closeCount = 0
            let step = reverse ? -1 : 1
            var offset = reverse ? length - 1 : 0
            while offset >= 0 && offset < length {
                if units[offset] == closeUnit {
                    closeCount += 1
                } else if units[offset] == openUnit {
                    closeCount -= 1
                    if closeCount < 0 {
                        return lowerBound + offset
                    }
                }
                offset += step
            }
            return nil
        }
    }

    /// Adds a temporary emphasis effect to the character at the given location.
    /// - Parameters:
    ///   - location: The location of the character to emphasize
    ///   - scrollToRange: Set to true to scroll to the given range when emphasizing. Defaults to `false`.
    private func emphasizeCharacter(_ location: Int, scrollToRange: Bool = false) {
        guard let bracketPairEmphasis = configuration.appearance.bracketPairEmphasis else {
            return
        }

        let range = NSRange(location: location, length: 1)

        switch bracketPairEmphasis {
        case .flash:
            textView.emphasisManager?.addEmphasis(
                Emphasis(
                    range: range,
                    style: .standard,
                    flash: true,
                    inactive: false
                ),
                for: EmphasisGroup.brackets
            )
        case .bordered(let borderColor):
            textView.emphasisManager?.addEmphasis(
                Emphasis(
                    range: range,
                    style: .outline(color: borderColor),
                    flash: false,
                    inactive: false
                ),
                for: EmphasisGroup.brackets
            )
        case .underline(let underlineColor):
            textView.emphasisManager?.addEmphasis(
                Emphasis(
                    range: range,
                    style: .underline(color: underlineColor),
                    flash: false,
                    inactive: false
                ),
                for: EmphasisGroup.brackets
            )
        }
    }
}
