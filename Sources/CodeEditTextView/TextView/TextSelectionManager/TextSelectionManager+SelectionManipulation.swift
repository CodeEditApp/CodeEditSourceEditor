//
//  TextSelectionManager+SelectionManipulation.swift
//  
//
//  Created by Khan Winter on 8/26/23.
//

import AppKit

extension TextSelectionManager {
    // MARK: - Range Of Selection

    /// Creates a range for a new selection given a starting point, direction, and destination.
    /// - Parameters:
    ///   - offset: The location to start the selection from.
    ///   - direction: The direction the selection should be created in.
    ///   - destination: Determines how far the selection is.
    ///   - decomposeCharacters: Set to `true` to treat grapheme clusters as individual characters.
    /// - Returns: A range of a new selection based on the direction and destination.
    public func rangeOfSelection(
        from offset: Int,
        direction: Direction,
        destination: Destination,
        decomposeCharacters: Bool = false
    ) -> NSRange {
        switch direction {
        case .backward:
            return extendSelection(from: offset, destination: destination, delta: -1)
        case .forward:
            return extendSelection(from: offset, destination: destination, delta: 1)
        case .up: // TODO: up
            return NSRange(location: offset, length: 0)
        case .down: // TODO: down
            return NSRange(location: offset, length: 0)
        }
    }

    /// Extends a selection from the given offset determining the length by the destination.
    ///
    /// Returns a new range that needs to be merged with an existing selection range using `NSRange.formUnion`
    ///
    /// - Parameters:
    ///   - offset: The location to start extending the selection from.
    ///   - destination: Determines how far the selection is extended.
    ///   - delta: The direction the selection should be extended. `1` for forwards, `-1` for backwards.
    ///   - decomposeCharacters: Set to `true` to treat grapheme clusters as individual characters.
    /// - Returns: A new range to merge with a selection.
    private func extendSelection(
        from offset: Int,
        destination: Destination,
        delta: Int,
        decomposeCharacters: Bool = false
    ) -> NSRange {
        guard let string = textStorage?.string as NSString? else { return NSRange(location: offset, length: 0) }

        switch destination {
        case .character:
            return extendSelectionCharacter(
                string: string,
                from: offset,
                delta: delta,
                decomposeCharacters: decomposeCharacters
            )
        case .word:
            return extendSelectionWord(string: string, from: offset, delta: delta)
        case .line:
            return extendSelectionLine(string: string, from: offset, delta: delta)
        case .container:
            return extendSelectionContainer(from: offset, delta: delta)
        case .document:
            if delta > 0 {
                return NSRange(location: offset, length: string.length - offset)
            } else {
                return NSRange(location: 0, length: offset)
            }
        }
    }

    // MARK: - Horizontal Methods

    /// Extends the selection by a single character.
    ///
    /// The range returned from this method can be longer than `1` character if the character in the extended direction
    /// is a member of a grapheme cluster.
    ///
    /// - Parameters:
    ///   - string: The reference string to use.
    ///   - offset: The location to start extending the selection from.
    ///   - delta: The direction the selection should be extended. `1` for forwards, `-1` for backwards.
    ///   - decomposeCharacters: Set to `true` to treat grapheme clusters as individual characters.
    /// - Returns: The range of the extended selection.
    private func extendSelectionCharacter(
        string: NSString,
        from offset: Int,
        delta: Int,
        decomposeCharacters: Bool
    ) -> NSRange {
        let range = delta > 0 ? NSRange(location: offset, length: 1) : NSRange(location: offset - 1, length: 1)
        if decomposeCharacters {
            return range
        } else {
            return string.rangeOfComposedCharacterSequences(for: range)
        }
    }

    /// Extends the selection by one "word".
    ///
    /// Words in this case begin after encountering an alphanumeric character, and extend until either a whitespace
    /// or punctuation character.
    ///
    /// - Parameters:
    ///   - string: The reference string to use.
    ///   - offset: The location to start extending the selection from.
    ///   - delta: The direction the selection should be extended. `1` for forwards, `-1` for backwards.
    /// - Returns: The range of the extended selection.
    private func extendSelectionWord(string: NSString, from offset: Int, delta: Int) -> NSRange {
        var enumerationOptions: NSString.EnumerationOptions = .byCaretPositions
        if delta < 0 {
            enumerationOptions.formUnion(.reverse)
        }
        guard let line = layoutManager?.textLineForOffset(offset),
              let lineFragment = line.data.typesetter.lineFragments.getLine(atIndex: offset - line.range.location)
        else {
            return NSRange(location: offset, length: 0)
        }
        let lineStart = line.range.location + lineFragment.range.location
        let lineEnd = line.range.location + lineFragment.range.max
        var rangeToDelete = NSRange(location: offset, length: 0)

        var hasFoundValidWordChar = false
        string.enumerateSubstrings(
            in: NSRange(
                location: delta > 0 ? offset : lineStart,
                length: delta > 0 ? lineEnd - offset : offset - lineStart
            ),
            options: enumerationOptions
        ) { substring, _, _, stop in
            guard let substring = substring else {
                stop.pointee = true
                return
            }

            if hasFoundValidWordChar && CharacterSet
                .whitespacesWithoutNewlines
                .union(.punctuationCharacters)
                .isSuperset(of: CharacterSet(charactersIn: substring)) {
                stop.pointee = true
                return
            } else if CharacterSet.alphanumerics.isSuperset(of: CharacterSet(charactersIn: substring)) {
                hasFoundValidWordChar = true
            }
            rangeToDelete.length += substring.count

            if delta < 0 {
                rangeToDelete.location -= substring.count
            }
        }

        return rangeToDelete
    }

    /// Extends the selection by one line in the direction specified.
    ///
    /// If extending backwards, this method will return the beginning of the leading non-whitespace characters
    /// in the line. If the offset is located in the leading whitespace it will return the real line beginning.
    /// For Example
    /// ```
    /// ^ = offset, ^--^ = returned range
    /// Line:
    ///      Loren Ipsum
    ///            ^
    /// Extend 1st Call:
    ///      Loren Ipsum
    ///      ^-----^
    /// Extend 2nd Call:
    ///      Loren Ipsum
    /// ^----^
    /// ```
    ///
    /// - Parameters:
    ///   - string: The reference string to use.
    ///   - offset: The location to start extending the selection from.
    ///   - delta: The direction the selection should be extended. `1` for forwards, `-1` for backwards.
    /// - Returns: The range of the extended selection.
    private func extendSelectionLine(string: NSString, from offset: Int, delta: Int) -> NSRange {
        guard let line = layoutManager?.textLineForOffset(offset),
              let lineFragment = line.data.typesetter.lineFragments.getLine(atIndex: offset - line.range.location)
        else {
            return NSRange(location: offset, length: 0)
        }
        let lineBound = delta > 0
        ? line.range.location + lineFragment.range.max
        : line.range.location + lineFragment.range.location

        var foundRange = NSRange(
            location: min(lineBound, offset),
            length: max(lineBound, offset) - min(lineBound, offset)
        )
        let originalFoundRange = foundRange

        // Only do this if we're going backwards.
        if delta < 0 {
            string.enumerateSubstrings(in: foundRange, options: .byCaretPositions) { substring, _, _, stop in
                if let substring = substring as String? {
                    if CharacterSet.whitespacesWithoutNewlines.isSuperset(of: CharacterSet(charactersIn: substring)) {
                        foundRange.location += 1
                        foundRange.length -= 1
                    } else {
                        stop.pointee = true
                    }
                } else {
                    stop.pointee = true
                }
            }
        }

        return foundRange.length == 0 ? originalFoundRange : foundRange
    }

    /// Extends a selection one "container" long.
    /// - Parameters:
    ///   - offset: The location to start extending the selection from.
    ///   - delta: The direction the selection should be extended. `1` for forwards, `-1` for backwards.
    /// - Returns: The range of the extended selection.
    private func extendSelectionContainer(from offset: Int, delta: Int) -> NSRange {
        guard let layoutView, let endOffset = layoutManager?.textOffsetAtPoint(
            CGPoint(
                x: delta > 0 ? layoutView.frame.maxX : layoutView.frame.minX,
                y: delta > 0 ? layoutView.frame.maxY : layoutView.frame.minY
            )
        ) else {
            return NSRange(location: offset, length: 0)
        }
        return endOffset > offset
        ? NSRange(location: offset, length: endOffset - offset)
        : NSRange(location: endOffset, length: offset - endOffset)
    }
}
