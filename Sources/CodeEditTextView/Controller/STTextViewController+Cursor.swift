//
//  STTextViewController+Cursor.swift
//  
//
//  Created by Elias Wahl on 15.03.23.
//

import Foundation
import AppKit

extension STTextViewController {
    func setCursorPosition(_ position: (Int, Int)) {
        guard let provider = textView.textLayoutManager.textContentManager else {
            return
        }

        var (line, column) = position
        let string = textView.string
        if line > 0 {
            if string.isEmpty {
                // If the file is blank, automatically place the cursor in the first index.
                let range = NSRange(string.startIndex..<string.endIndex, in: string)
                if let newRange = NSTextRange(range, provider: provider) {
                    _ = self.textView.becomeFirstResponder()
                    self.textView.setSelectedRange(newRange)
                    return
                }
            }

            string.enumerateSubstrings(in: string.startIndex..<string.endIndex) { _, lineRange, _, done in
                line -= 1
                if line < 1 {
                    // If `column` exceeds the line length, set cursor to the end of the line.
                    // min = line begining, max = line end.
                    let index = max(
                        lineRange.lowerBound,
                        min(lineRange.upperBound, string.index(lineRange.lowerBound, offsetBy: column - 1))
                    )
                    if let newRange = NSTextRange(NSRange(index..<index, in: string), provider: provider) {
                        self.textView.setSelectedRange(newRange)
                    }
                    done = true
                } else {
                    done = false
                }
            }
        }
    }

    func updateCursorPosition() {
        guard let textLayoutManager = textView.textLayoutManager as NSTextLayoutManager?,
              let textContentManager = textLayoutManager.textContentManager as NSTextContentManager?,
              let insertionPointLocation = textLayoutManager.insertionPointLocations.first,
              let documentStartLocation = textLayoutManager.documentRange.location as NSTextLocation?,
              let documentEndLocation = textLayoutManager.documentRange.endLocation as NSTextLocation?
        else {
            return
        }

        let textElements = textContentManager.textElements(
            for: NSTextRange(location: textLayoutManager.documentRange.location, end: insertionPointLocation)!)
        var line = textElements.count

        textLayoutManager.enumerateTextSegments(
                in: NSTextRange(location: insertionPointLocation),
                type: .standard,
                options: [.rangeNotRequired, .upstreamAffinity]
            ) { _, textSegmentFrame, _, _ -> Bool
                in
                var col = 1
                /// If the cursor is at the end of the document:
                if textLayoutManager.offset(from: insertionPointLocation, to: documentEndLocation) == 0 {
                    /// If document is empty:
                    if textLayoutManager.offset(from: documentStartLocation, to: documentEndLocation) == 0 {
                        self.cursorPosition.wrappedValue = (1, 1)
                        return false
                    }
                    guard let cursorTextFragment = textLayoutManager.textLayoutFragment(for: textSegmentFrame.origin),
                          let cursorTextLineFragment = cursorTextFragment.textLineFragments.last
                    else { return false }

                    col = cursorTextLineFragment.characterRange.length + 1
                    if col == 1 { line += 1 }
                } else {
                    guard let cursorTextLineFragment = textLayoutManager.textLineFragment(at: insertionPointLocation)
                    else { return false }

                    /// +1, because we start with the first character with 1
                    let tempCol = cursorTextLineFragment.characterIndex(for: textSegmentFrame.origin)
                    let result = tempCol.addingReportingOverflow(1)

                    if !result.overflow { col = result.partialValue }
                    /// If cursor is at end of line add 1:
                    if cursorTextLineFragment.characterRange.length != 1 &&
                        (cursorTextLineFragment.typographicBounds.width == (textSegmentFrame.maxX + 5.0)) {
                        col += 1
                    }

                    /// If cursor is at first character of line, the current line is not being included
                    if col == 1 { line += 1 }
                }

                DispatchQueue.main.async {
                    self.cursorPosition.wrappedValue = (line, col)
                }
                return false
            }
        }
}
