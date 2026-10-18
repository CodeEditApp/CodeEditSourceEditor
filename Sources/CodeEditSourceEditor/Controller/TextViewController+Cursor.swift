//
//  TextViewController+Cursor.swift
//  CodeEditSourceEditor
//
//  Created by Elias Wahl on 15.03.23.
//

import Foundation
import AppKit
import CodeEditTextView

extension TextViewController {
    /// Resolves a 1-indexed column on `line` to a UTF-16 offset, clamped to the line's content. Restored state and
    /// LSP positions can be out of range, and must not spill onto the next line.
    func characterOffset(in line: TextLineStorage<TextLine>.TextLinePosition, forColumn column: Int) -> Int {
        let range = line.range
        let string = textView.textStorage.string as NSString
        var contentLength = range.length
        if contentLength > 0 {
            let last = string.character(at: range.max - 1)
            if last == 0x0A || last == 0x0D { // \n or \r
                contentLength -= 1
                if last == 0x0A, contentLength > 0, string.character(at: range.max - 2) == 0x0D { // \r\n
                    contentLength -= 1
                }
            }
        }
        return range.location + min(max(column - 1, 0), contentLength)
    }

    /// Sets new cursor positions.
    /// - Parameter positions: The positions to set. Lines and columns are 1-indexed.
    public func setCursorPositions(_ positions: [CursorPosition], scrollToVisible: Bool = false) {
        if isPostingCursorNotification { return }
        var newSelectedRanges: [NSRange] = []
        for position in positions {
            guard (position.start.isPositive && position.end?.isPositive ?? true)
                    || (position.range != .notFound) else {
                continue
            }

            if position.range == .notFound {
                if textView.textStorage.length == 0 {
                    // If the file is blank, automatically place the cursor in the first index.
                    newSelectedRanges.append(NSRange(location: 0, length: 0))
                } else if let linePosition = textView.layoutManager.textLineForIndex(position.start.line - 1) {
                    // If this is a valid line, set the new position
                    let startCharacter = characterOffset(in: linePosition, forColumn: position.start.column)
                    if let end = position.end, let endLine = textView.layoutManager.textLineForIndex(end.line - 1) {
                        let endCharacter = characterOffset(in: endLine, forColumn: end.column)
                        // An end before the start would make a negative-length range.
                        newSelectedRanges.append(NSRange(
                            start: min(startCharacter, endCharacter),
                            end: max(startCharacter, endCharacter)
                        ))
                    } else {
                        newSelectedRanges.append(NSRange(location: startCharacter, length: 0))
                    }
                }
            } else {
                newSelectedRanges.append(position.range)
            }
        }
        textView.selectionManager.setSelectedRanges(newSelectedRanges)

        if scrollToVisible {
            textView.scrollSelectionToVisible()
        }
    }

    /// Update the ``TextViewController/cursorPositions`` variable with new text selections from the text view.
    func updateCursorPosition() {
        var positions: [CursorPosition] = []
        for selectedRange in textView.selectionManager.textSelections {
            guard let linePosition = textView.layoutManager.textLineForOffset(selectedRange.range.location) else {
                continue
            }
            let start = CursorPosition.Position(
                line: linePosition.index + 1,
                column: (selectedRange.range.location - linePosition.range.location) + 1
            )
            let end = if !selectedRange.range.isEmpty,
                         let endPosition = textView.layoutManager.textLineForOffset(selectedRange.range.max) {
                CursorPosition.Position(
                    line: endPosition.index + 1,
                    column: selectedRange.range.max - endPosition.range.location + 1
                )
            } else {
                CursorPosition.Position?.none
            }
            positions.append(CursorPosition(range: selectedRange.range, start: start, end: end))
        }

        isPostingCursorNotification = true
        cursorPositions = positions.sorted(by: { $0.range.location < $1.range.location })
        NotificationCenter.default.post(name: Self.cursorPositionUpdatedNotification, object: self)
        for coordinator in self.textCoordinators.values() {
            coordinator.textViewDidChangeSelection(controller: self, newPositions: cursorPositions)
        }
        isPostingCursorNotification = false

        if let position = cursorPositions.first {
            suggestionTriggerModel.selectionUpdated(position)
        }
    }

    /// Fills out all properties on the given cursor position if it's missing either the range or line/column
    /// information.
    public func resolveCursorPosition(_ position: CursorPosition) -> CursorPosition? {
        var range = position.range
        if range == .notFound {
            guard position.start.line > 0, position.start.column > 0,
                    let linePosition = textView.layoutManager.textLineForIndex(position.start.line - 1) else {
                return nil
            }
            let startOffset = characterOffset(in: linePosition, forColumn: position.start.column)
            if let endPos = position.end,
               endPos.line > 0, endPos.column > 0,
               let endLinePosition = textView.layoutManager.textLineForIndex(endPos.line - 1) {
                let endOffset = characterOffset(in: endLinePosition, forColumn: endPos.column)
                range = NSRange(start: min(startOffset, endOffset), end: max(startOffset, endOffset))
            } else {
                range = NSRange(location: startOffset, length: 0)
            }
        }

        var start: CursorPosition.Position
        var end: CursorPosition.Position?

        guard let startLinePosition = textView.layoutManager.textLineForOffset(range.location) else {
            return nil
        }

        start = CursorPosition.Position(
            line: startLinePosition.index + 1,
            column: (range.location - startLinePosition.range.location) + 1
        )

        if !range.isEmpty {
            guard let endLinePosition = textView.layoutManager.textLineForOffset(range.max) else { return nil }
            end = CursorPosition.Position(
                line: endLinePosition.index + 1,
                column: (range.max - endLinePosition.range.location) + 1
            )
        }

        return CursorPosition(range: range, start: start, end: end)
    }
}
