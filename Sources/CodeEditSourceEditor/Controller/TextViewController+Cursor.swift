//
//  TextViewController+Cursor.swift
//  CodeEditSourceEditor
//
//  Created by Elias Wahl on 15.03.23.
//

import Foundation
import AppKit

extension TextViewController {
    /// Sets new cursor positions.
    /// - Parameter positions: The positions to set. Lines and columns are 1-indexed.
    public func setCursorPositions(_ positions: [CursorPosition], scrollToVisible: Bool = false) {
        if isPostingCursorNotification { return }
        var newSelectedRanges: [NSRange] = []
        for position in positions {
            let line = position.line
            let column = position.column
            guard (line > 0 && column > 0) || (position.range != .notFound) else { continue }

            if position.range == .notFound {
                if textView.textStorage.length == 0 {
                    // If the file is blank, automatically place the cursor in the first index.
                    newSelectedRanges.append(NSRange(location: 0, length: 0))
                } else if let linePosition = textView.layoutManager.textLineForIndex(line - 1) {
                    // If this is a valid line, set the new position
                    let index = linePosition.range.lowerBound + min(linePosition.range.upperBound, column - 1)
                    newSelectedRanges.append(NSRange(location: index, length: 0))
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
            let column = (selectedRange.range.location - linePosition.range.location) + 1
            let line = linePosition.index + 1
            positions.append(CursorPosition(range: selectedRange.range, line: line, column: column))
        }

        isPostingCursorNotification = true
        cursorPositions = positions.sorted(by: { $0.range.location < $1.range.location })
        NotificationCenter.default.post(name: Self.cursorPositionUpdatedNotification, object: self)
        for coordinator in self.textCoordinators.values() {
            coordinator.textViewDidChangeSelection(controller: self, newPositions: cursorPositions)
        }
        isPostingCursorNotification = false

        if let completionDelegate = completionDelegate, let position = cursorPositions.first {
            SuggestionController.shared.cursorsUpdated(textView: self, delegate: completionDelegate, position: position)
        }
    }

    /// Fills out all properties on the given cursor position if it's missing either the range or line/column
    /// information.
    func resolveCursorPosition(_ position: CursorPosition) -> CursorPosition? {
        var range = position.range
        if range == .notFound {
            guard position.line > 0, position.column > 0,
                    let linePosition = textView.layoutManager.textLineForIndex(position.line - 1) else {
                return nil
            }
            range = NSRange(location: linePosition.range.location + position.column, length: 0)
        }

        var line = position.line
        var column = position.column
        if position.line <= 0 || position.column <= 0 {
            guard range != .notFound, let linePosition = textView.layoutManager.textLineForOffset(range.location) else {
                return nil
            }
            column = (range.location - linePosition.range.location) + 1
            line = linePosition.index + 1
        }

        return CursorPosition(range: range, line: line, column: column)
    }
}
