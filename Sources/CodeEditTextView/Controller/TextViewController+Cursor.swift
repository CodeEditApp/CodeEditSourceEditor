//
//  TextViewController+Cursor.swift
//
//
//  Created by Elias Wahl on 15.03.23.
//

import Foundation
import AppKit

extension TextViewController {
    /// Sets a new cursor position.
    /// - Parameter position: The position to set. Lines and columns are 1-indexed.
    func setCursorPosition(_ position: (Int, Int)) {
        let (line, column) = position
        guard line >= 0 && column >= 0 else { return }

        if textView.textStorage.length == 0 {
            // If the file is blank, automatically place the cursor in the first index.
            let range = NSRange(location: 0, length: 0)
            _ = self.textView.becomeFirstResponder()
            self.textView.selectionManager.setSelectedRange(range)
        } else if line - 1 >= 0, let linePosition = textView.layoutManager.textLineForIndex(line - 1) {
            // If this is a valid line, set the new position
            let index = max(
                linePosition.range.lowerBound,
                min(linePosition.range.upperBound, column - 1)
            )
            self.textView.selectionManager.setSelectedRange(NSRange(location: index, length: 0))
        }
    }

    func updateCursorPosition() {
        // Get the smallest cursor position.
        guard let selectedRange = textView
            .selectionManager
            .textSelections
            .sorted(by: { $0.range.lowerBound < $1.range.lowerBound})
            .first else {
            return
        }

        // Get the line it's in
        guard let linePosition = textView.layoutManager.textLineForOffset(selectedRange.range.location) else { return }
        let column = selectedRange.range.location - linePosition.range.location
        cursorPosition.wrappedValue = (linePosition.index + 1, column + 1)
    }
}
