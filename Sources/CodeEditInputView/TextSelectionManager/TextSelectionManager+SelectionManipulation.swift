//
//  TextSelectionManager+SelectionManipulation.swift
//  
//
//  Created by Khan Winter on 8/26/23.
//

import AppKit

public extension TextSelectionManager {
    // MARK: - Range Of Selection

    /// Creates a range for a new selection given a starting point, direction, and destination.
    /// - Parameters:
    ///   - offset: The location to start the selection from.
    ///   - direction: The direction the selection should be created in.
    ///   - destination: Determines how far the selection is.
    ///   - decomposeCharacters: Set to `true` to treat grapheme clusters as individual characters.
    ///   - suggestedXPos: The suggested x position to stick to.
    /// - Returns: A range of a new selection based on the direction and destination.
    func rangeOfSelection(
        from offset: Int,
        direction: Direction,
        destination: Destination,
        decomposeCharacters: Bool = false,
        suggestedXPos: CGFloat? = nil
    ) -> NSRange {
        switch direction {
        case .backward:
            guard offset > 0 else { return NSRange(location: offset, length: 0) } // Can't go backwards beyond 0
            return extendSelection(
                from: offset,
                destination: destination,
                delta: -1,
                decomposeCharacters: decomposeCharacters
            )
        case .forward:
            return extendSelection(
                from: offset,
                destination: destination,
                delta: 1,
                decomposeCharacters: decomposeCharacters
            )
        case .up:
            return extendSelectionVertical(
                from: offset,
                destination: destination,
                up: true,
                suggestedXPos: suggestedXPos
            )
        case .down:
            return extendSelectionVertical(
                from: offset,
                destination: destination,
                up: false,
                suggestedXPos: suggestedXPos
            )
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
        case .line, .container:
            return extendSelectionLine(string: string, from: offset, delta: delta)
        case .visualLine:
            return extendSelectionVisualLine(string: string, from: offset, delta: delta)
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
        if delta > 0 && offset == string.length - 1 {
            return NSRange(location: offset, length: 0)
        } else if delta < 0 && offset == 0 {
            return NSRange(location: 0, length: 0)
        }

        return decomposeCharacters ? range : string.rangeOfComposedCharacterSequences(for: range)
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
        var rangeToDelete = NSRange(location: offset, length: 0)

        var hasFoundValidWordChar = false
        string.enumerateSubstrings(
            in: NSRange(location: delta > 0 ? offset : 0, length: delta > 0 ? string.length - offset : offset),
            options: enumerationOptions
        ) { substring, _, _, stop in
            guard let substring = substring else {
                stop.pointee = true
                return
            }

            if hasFoundValidWordChar && CharacterSet.punctuationCharacters
                .union(.whitespacesAndNewlines)
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

    /// Extends the selection by one visual line in the direction specified (eg one line fragment).
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
    private func extendSelectionVisualLine(string: NSString, from offset: Int, delta: Int) -> NSRange {
        guard let line = layoutManager?.textLineForOffset(offset),
              let lineFragment = line.data.typesetter.lineFragments.getLine(atIndex: offset - line.range.location)
        else {
            return NSRange(location: offset, length: 0)
        }
        let lineBound = delta > 0
        ? line.range.location + min(
            lineFragment.range.max,
            line.range.max - line.range.location - (layoutManager?.detectedLineEnding.length ?? 1)
        )
        : line.range.location + lineFragment.range.location

        return _extendSelectionLine(string: string, lineBound: lineBound, offset: offset, delta: delta)
    }

    /// Extends the selection by one real line in the direction specified.
    ///
    /// If extending backwards, this method will return the beginning of the leading non-whitespace characters
    /// in the line. If the offset is located in the leading whitespace it will return the real line beginning.
    ///
    /// - Parameters:
    ///   - string: The reference string to use.
    ///   - offset: The location to start extending the selection from.
    ///   - delta: The direction the selection should be extended. `1` for forwards, `-1` for backwards.
    /// - Returns: The range of the extended selection.
    private func extendSelectionLine(string: NSString, from offset: Int, delta: Int) -> NSRange {
        guard let line = layoutManager?.textLineForOffset(offset) else {
            return NSRange(location: offset, length: 0)
        }
        let lineBound = delta > 0
        ? line.range.max - (layoutManager?.detectedLineEnding.length ?? 1)
        : line.range.location

        return _extendSelectionLine(string: string, lineBound: lineBound, offset: offset, delta: delta)
    }

    /// Common code for `extendSelectionLine` and `extendSelectionVisualLine`
    private func _extendSelectionLine(
        string: NSString,
        lineBound: Int,
        offset: Int,
        delta: Int
    ) -> NSRange {
        var foundRange = NSRange(
            location: min(lineBound, offset),
            length: max(lineBound, offset) - min(lineBound, offset)
        )
        let originalFoundRange = foundRange

        // Only do this if we're going backwards.
        if delta < 0 {
            foundRange = findBeginningOfLineText(string: string, initialRange: foundRange)
        }

        return foundRange.length == 0 ? originalFoundRange : foundRange
    }

    /// Finds the beginning of text in a line not including whitespace.
    /// - Parameters:
    ///   - string: The string to look in.
    ///   - initialRange: The range to begin looking from.
    /// - Returns: A new range to replace the given range for the line.
    private func findBeginningOfLineText(string: NSString, initialRange: NSRange) -> NSRange {
        var foundRange = initialRange
        string.enumerateSubstrings(in: foundRange, options: .byCaretPositions) { substring, _, _, stop in
            if let substring = substring as String? {
                if CharacterSet
                    .whitespacesAndNewlines.subtracting(.newlines)
                    .isSuperset(of: CharacterSet(charactersIn: substring)) {
                    foundRange.location += 1
                    foundRange.length -= 1
                } else {
                    stop.pointee = true
                }
            } else {
                stop.pointee = true
            }
        }
        return foundRange
    }

    // MARK: - Vertical Methods

    /// Extends a selection from the given offset vertically to the destination.
    /// - Parameters:
    ///   - offset: The offset to extend from.
    ///   - destination: The destination to extend to.
    ///   - up: Set to true if extending up.
    ///   - suggestedXPos: The suggested x position to stick to.
    /// - Returns: The range of the extended selection.
    private func extendSelectionVertical(
        from offset: Int,
        destination: Destination,
        up: Bool,
        suggestedXPos: CGFloat?
    ) -> NSRange {
        switch destination {
        case .character:
            return extendSelectionVerticalCharacter(from: offset, up: up, suggestedXPos: suggestedXPos)
        case .word, .line, .visualLine:
            return extendSelectionVerticalLine(from: offset, up: up)
        case .container:
            return extendSelectionContainer(from: offset, delta: up ? 1 : -1)
        case .document:
            if up {
                return NSRange(location: 0, length: offset)
            } else {
                return NSRange(location: offset, length: (textStorage?.length ?? 0) - offset - 1)
            }
        }
    }

    /// Extends the selection to the nearest character vertically.
    /// - Parameters:
    ///   - offset: The offset to extend from.
    ///   - up: Set to true if extending up.
    ///   - suggestedXPos: The suggested x position to stick to.
    /// - Returns: The range of the extended selection.
    private func extendSelectionVerticalCharacter(
        from offset: Int,
        up: Bool,
        suggestedXPos: CGFloat?
    ) -> NSRange {
        guard let point = layoutManager?.rectForOffset(offset)?.origin,
              let newOffset = layoutManager?.textOffsetAtPoint(
                CGPoint(
                    x: suggestedXPos == nil ? point.x : suggestedXPos!,
                    y: point.y - (layoutManager?.estimateLineHeight() ?? 2.0)/2 * (up ? 1 : -3)
                )
              ) else {
            return NSRange(location: offset, length: 0)
        }

        return NSRange(
            location: up ? newOffset : offset,
            length: up ? offset - newOffset : newOffset - offset
        )
    }

    /// Extends the selection to the nearest line vertically.
    ///
    /// If moving up and the offset is in the middle of the line, it first extends it to the beginning of the line.
    /// On the second call, it will extend it to the beginning of the previous line. When moving down, the
    /// same thing will happen in the opposite direction.
    ///
    /// - Parameters:
    ///   - offset: The offset to extend from.
    ///   - up: Set to true if extending up.
    ///   - suggestedXPos: The suggested x position to stick to.
    /// - Returns: The range of the extended selection.
    private func extendSelectionVerticalLine(
        from offset: Int,
        up: Bool
    ) -> NSRange {
        // Important distinction here, when moving up/down on a line and in the middle of the line, we move to the
        // beginning/end of the *entire* line, not the line fragment.
        guard let line = layoutManager?.textLineForOffset(offset) else {
            return NSRange(location: offset, length: 0)
        }
        if up && line.range.location != offset {
            return NSRange(location: line.range.location, length: offset - line.index)
        } else if !up && line.range.max - (layoutManager?.detectedLineEnding.length ?? 0) != offset {
            return NSRange(
                location: offset,
                length: line.range.max - offset - (layoutManager?.detectedLineEnding.length ?? 0)
            )
        } else {
            let nextQueryIndex = up ? max(line.range.location - 1, 0) : min(line.range.max, (textStorage?.length ?? 0))
            guard let nextLine = layoutManager?.textLineForOffset(nextQueryIndex) else {
                return NSRange(location: offset, length: 0)
            }
            return NSRange(
                location: up ? nextLine.range.location : offset,
                length: up
                ? offset - nextLine.range.location
                : nextLine.range.max - offset - (layoutManager?.detectedLineEnding.length ?? 0)
            )
        }
    }

    /// Extends a selection one "container" long.
    /// - Parameters:
    ///   - offset: The location to start extending the selection from.
    ///   - delta: The direction the selection should be extended. `1` for forwards, `-1` for backwards.
    /// - Returns: The range of the extended selection.
    private func extendSelectionContainer(from offset: Int, delta: Int) -> NSRange {
        // TODO: Needs to force layout for the rect being moved by.
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
