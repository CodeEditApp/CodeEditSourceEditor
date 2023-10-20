//
//  TextLayoutManager+Public.swift
//  
//
//  Created by Khan Winter on 9/13/23.
//

import AppKit

extension TextLayoutManager {
    public func estimatedHeight() -> CGFloat {
        max(lineStorage.height, estimateLineHeight())
    }

    public func estimatedWidth() -> CGFloat {
        maxLineWidth
    }

    public func textLineForPosition(_ posY: CGFloat) -> TextLineStorage<TextLine>.TextLinePosition? {
        lineStorage.getLine(atPosition: posY)
    }

    public func textLineForOffset(_ offset: Int) -> TextLineStorage<TextLine>.TextLinePosition? {
        if offset == lineStorage.length {
            return lineStorage.last
        } else {
            return lineStorage.getLine(atOffset: offset)
        }
    }

    /// Finds text line and returns it if found.
    /// Lines are 0 indexed.
    /// - Parameter index: The line to find.
    /// - Returns: The text line position if any, `nil` if the index is out of bounds.
    public func textLineForIndex(_ index: Int) -> TextLineStorage<TextLine>.TextLinePosition? {
        guard index >= 0 && index < lineStorage.count else { return nil }
        return lineStorage.getLine(atIndex: index)
    }

    public func textOffsetAtPoint(_ point: CGPoint) -> Int? {
        guard point.y <= estimatedHeight() else { // End position is a special case.
            return textStorage.length
        }
        guard let position = lineStorage.getLine(atPosition: point.y),
              let fragmentPosition = position.data.typesetter.lineFragments.getLine(
                atPosition: point.y - position.yPos
              ) else {
            return nil
        }
        let fragment = fragmentPosition.data

        if fragment.width == 0 {
            return position.range.location + fragmentPosition.range.location
        } else if fragment.width < point.x - edgeInsets.left {
            let fragmentRange = CTLineGetStringRange(fragment.ctLine)
            let globalFragmentRange = NSRange(
                location: position.range.location + fragmentRange.location,
                length: fragmentRange.length
            )
            let endPosition = position.range.location + fragmentRange.location + fragmentRange.length
            // Return eol
            return endPosition - (
                // Before the eol character (insertion point is before the eol)
                // And the line *has* an eol character
                fragmentPosition.range.max == position.range.max
                && LineEnding(line: textStorage.substring(from: globalFragmentRange) ?? "") != nil
                ? detectedLineEnding.length : 0
            )
        } else {
            // Somewhere in the fragment
            let fragmentIndex = CTLineGetStringIndexForPosition(
                fragment.ctLine,
                CGPoint(x: point.x - edgeInsets.left, y: fragment.height/2)
            )
            return position.range.location + fragmentIndex
        }
    }

    /// Find a position for the character at a given offset.
    /// Returns the rect of the character at the given offset.
    /// The rect may represent more than one unicode unit, for instance if the offset is at the beginning of an
    /// emoji or non-latin glyph.
    /// - Parameter offset: The offset to create the rect for.
    /// - Returns: The found rect for the given offset.
    public func rectForOffset(_ offset: Int) -> CGRect? {
        guard offset != lineStorage.length else {
            return rectForEndOffset()
        }
        guard let linePosition = lineStorage.getLine(atOffset: offset) else {
            return nil
        }
        if linePosition.data.lineFragments.isEmpty {
            let newHeight = ensureLayoutFor(position: linePosition)
            if linePosition.height != newHeight {
                delegate?.layoutManagerHeightDidUpdate(newHeight: lineStorage.height)
            }
        }

        guard let fragmentPosition = linePosition.data.typesetter.lineFragments.getLine(
            atOffset: offset - linePosition.range.location
        ) else {
            return nil
        }

        // Get the *real* length of the character at the offset. If this is a surrogate pair it'll return the correct
        // length of the character at the offset.
        let realRange = (textStorage.string as NSString).rangeOfComposedCharacterSequence(at: offset)

        let minXPos = CTLineGetOffsetForStringIndex(
            fragmentPosition.data.ctLine,
            realRange.location - linePosition.range.location, // CTLines have the same relative range as the line
            nil
        )
        let maxXPos = CTLineGetOffsetForStringIndex(
            fragmentPosition.data.ctLine,
            realRange.max - linePosition.range.location,
            nil
        )

        return CGRect(
            x: minXPos + edgeInsets.left,
            y: linePosition.yPos + fragmentPosition.yPos,
            width: maxXPos - minXPos,
            height: fragmentPosition.data.scaledHeight
        )
    }

    /// Finds a suitable cursor rect for the end position.
    /// - Returns: A CGRect if it could be created.
    private func rectForEndOffset() -> CGRect? {
        if let last = lineStorage.last {
            if last.range.isEmpty {
                // Return a 0-width rect at the end of the last line.
                return CGRect(x: edgeInsets.left, y: last.yPos, width: 0, height: last.height)
            } else if let rect = rectForOffset(last.range.max - 1) {
                return  CGRect(x: rect.maxX, y: rect.minY, width: 0, height: rect.height)
            }
        } else if lineStorage.isEmpty {
            // Text is empty, create a new rect with estimated height at the origin
            return CGRect(
                x: edgeInsets.left,
                y: 0.0,
                width: 0,
                height: estimateLineHeight()
            )
        }
        return nil
    }

    /// Forces layout calculation for all lines up to and including the given offset.
    /// - Parameter offset: The offset to ensure layout until.
    public func ensureLayoutUntil(_ offset: Int) {
        guard let linePosition = lineStorage.getLine(atOffset: offset),
              let visibleRect = delegate?.visibleRect,
              visibleRect.maxY < linePosition.yPos + linePosition.height,
              let startingLinePosition = lineStorage.getLine(atPosition: visibleRect.minY)
        else {
            return
        }
        let originalHeight = lineStorage.height

        for linePosition in lineStorage.linesInRange(
            NSRange(
                location: startingLinePosition.range.location,
                length: linePosition.range.max - startingLinePosition.range.location
            )
        ) {
            let height = ensureLayoutFor(position: linePosition)
            if height != linePosition.height {
                lineStorage.update(
                    atIndex: linePosition.range.location,
                    delta: 0,
                    deltaHeight: height - linePosition.height
                )
            }
        }

        if originalHeight != lineStorage.height || layoutView?.frame.size.height != lineStorage.height {
            delegate?.layoutManagerHeightDidUpdate(newHeight: lineStorage.height)
        }
    }

    /// Forces layout calculation for all lines up to and including the given offset.
    /// - Parameter offset: The offset to ensure layout until.
    private func ensureLayoutFor(position: TextLineStorage<TextLine>.TextLinePosition) -> CGFloat {
        position.data.prepareForDisplay(
            maxWidth: maxLineLayoutWidth,
            lineHeightMultiplier: lineHeightMultiplier,
            estimatedLineHeight: estimateLineHeight(),
            range: position.range,
            stringRef: textStorage
        )
        var height: CGFloat = 0
        for fragmentPosition in position.data.lineFragments {
            height += fragmentPosition.data.scaledHeight
        }
        return height
    }
}
