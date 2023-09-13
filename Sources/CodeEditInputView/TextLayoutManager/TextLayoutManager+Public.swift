//
//  TextLayoutManager+Public.swift
//  
//
//  Created by Khan Winter on 9/13/23.
//

import AppKit

extension TextLayoutManager {
    public func estimatedHeight() -> CGFloat {
        lineStorage.height
    }

    public func estimatedWidth() -> CGFloat {
        maxLineWidth
    }

    public func textLineForPosition(_ posY: CGFloat) -> TextLineStorage<TextLine>.TextLinePosition? {
        lineStorage.getLine(atPosition: posY)
    }

    public func textLineForOffset(_ offset: Int) -> TextLineStorage<TextLine>.TextLinePosition? {
        lineStorage.getLine(atIndex: offset)
    }

    public func textOffsetAtPoint(_ point: CGPoint) -> Int? {
        guard let position = lineStorage.getLine(atPosition: point.y),
              let fragmentPosition = position.data.typesetter.lineFragments.getLine(
                atPosition: point.y - position.yPos
              ) else {
            return nil
        }
        let fragment = fragmentPosition.data

        if fragment.width < point.x - edgeInsets.left {
            let fragmentRange = CTLineGetStringRange(fragment.ctLine)
            // Return eol
            return position.range.location + fragmentRange.location + fragmentRange.length - (
                // Before the eol character (insertion point is before the eol)
                fragmentPosition.range.max == position.range.max ?
                1 : detectedLineEnding.length
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
        guard let linePosition = lineStorage.getLine(atIndex: offset) else {
            return nil
        }
        if linePosition.data.lineFragments.isEmpty {
            let newHeight = ensureLayoutFor(position: linePosition)
            if linePosition.height != newHeight {
                delegate?.layoutManagerHeightDidUpdate(newHeight: lineStorage.height)
            }
        }

        guard let fragmentPosition = linePosition.data.typesetter.lineFragments.getLine(
            atIndex: offset - linePosition.range.location
        ) else {
            return nil
        }

        // Get the *real* length of the character at the offset. If this is a surrogate pair it'll return the correct
        // length of the character at the offset.
        let charLengthAtOffset = (textStorage.string as NSString).rangeOfComposedCharacterSequence(at: offset).length

        let minXPos = CTLineGetOffsetForStringIndex(
            fragmentPosition.data.ctLine,
            offset - linePosition.range.location,
            nil
        )
        let maxXPos = CTLineGetOffsetForStringIndex(
            fragmentPosition.data.ctLine,
            offset - linePosition.range.location + charLengthAtOffset,
            nil
        )

        return CGRect(
            x: minXPos + edgeInsets.left,
            y: linePosition.yPos + fragmentPosition.yPos,
            width: (maxXPos - minXPos) + edgeInsets.left,
            height: fragmentPosition.data.scaledHeight
        )
    }

    /// Forces layout calculation for all lines up to and including the given offset.
    /// - Parameter offset: The offset to ensure layout until.
    public func ensureLayoutUntil(_ offset: Int) {
        guard let linePosition = lineStorage.getLine(atIndex: offset),
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
            maxWidth: maxLineWidth,
            lineHeightMultiplier: lineHeightMultiplier,
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
