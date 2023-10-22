//
//  TextSelectionManager+FillRects.swift
//  
//
//  Created by Khan Winter on 10/22/23.
//

import Foundation

extension TextSelectionManager {
    /// Calculate a set of rects for a text selection suitable for highlighting the selection.
    /// - Parameters:
    ///   - rect: The bounding rect of available draw space.
    ///   - textSelection: The selection to use.
    /// - Returns: An array of rects that the selection overlaps.
    func getFillRects(in rect: NSRect, for textSelection: TextSelection) -> [CGRect] {
        guard let layoutManager else { return [] }
        let range = textSelection.range

        var fillRects: [CGRect] = []
        guard let firstLinePosition = layoutManager.lineStorage.getLine(atOffset: range.location),
              let lastLinePosition = range.max == layoutManager.lineStorage.length
                ? layoutManager.lineStorage.last
                : layoutManager.lineStorage.getLine(atOffset: range.max) else {
            return []
        }

        // Calculate the first line and any rects selected
        // If the last line position is not the same as the first, calculate any rects from that line.
        // If there's > 0 space between the first and last positions, add a rect between them to cover any
        // intermediate lines.

        fillRects.append(contentsOf: getFillRects(in: rect, selectionRange: range, forPosition: firstLinePosition))

        if lastLinePosition.range != firstLinePosition.range {
            fillRects.append(contentsOf: getFillRects(in: rect, selectionRange: range, forPosition: lastLinePosition))
        }

        if firstLinePosition.yPos + firstLinePosition.height < lastLinePosition.yPos {
            fillRects.append(CGRect(
                x: rect.minX,
                y: firstLinePosition.yPos + firstLinePosition.height,
                width: rect.width,
                height: lastLinePosition.yPos - (firstLinePosition.yPos + firstLinePosition.height)
            ))
        }

        return fillRects
    }

    /// Find fill rects for a specific line position.
    /// - Parameters:
    ///   - rect: The bounding rect of the overall view.
    ///   - range: The selected range to create fill rects for.
    ///   - linePosition: The line position to use.
    /// - Returns: An array of rects that the selection overlaps.
    private func getFillRects(
        in rect: NSRect,
        selectionRange range: NSRange,
        forPosition linePosition: TextLineStorage<TextLine>.TextLinePosition
    ) -> [CGRect] {
        guard let layoutManager else { return [] }
        var fillRects: [CGRect] = []

        // The selected range contains some portion of the line
        for fragmentPosition in linePosition.data.lineFragments {
            guard let fragmentRange = fragmentPosition
                .range
                .shifted(by: linePosition.range.location),
                  let intersectionRange = fragmentRange.intersection(range),
                  let minRect = layoutManager.rectForOffset(intersectionRange.location) else {
                continue
            }

            let maxRect: CGRect
            // If the selection is at the end of the line, or contains the end of the fragment, and is not the end
            // of the document, we select the entire line to the right of the selection point.
            if (fragmentRange.max <= range.max || range.contains(fragmentRange.max))
                && intersectionRange.max != layoutManager.lineStorage.length {
                maxRect = CGRect(
                    x: rect.maxX,
                    y: fragmentPosition.yPos + linePosition.yPos,
                    width: 0,
                    height: fragmentPosition.height
                )
            } else if let maxFragmentRect = layoutManager.rectForOffset(intersectionRange.max) {
                maxRect = maxFragmentRect
            } else {
                continue
            }

            fillRects.append(CGRect(
                x: minRect.origin.x,
                y: minRect.origin.y,
                width: maxRect.minX - minRect.minX,
                height: max(minRect.height, maxRect.height)
            ))
        }

        return fillRects
    }
}
