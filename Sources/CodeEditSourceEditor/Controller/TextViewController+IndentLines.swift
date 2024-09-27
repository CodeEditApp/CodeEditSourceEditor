//
//  TextViewController+IndentLines.swift
//
//
//  Created by Ludwig, Tom on 11.09.24.
//

import CodeEditTextView
import AppKit

extension TextViewController {
    public func handleIndent(inwards: Bool = false) {
        // Loop over cursor positions; if more than 1 don't check if multiple lines are selected
        guard let cursorPosition = cursorPositions.first else { return }

        guard let lineIndexes = getHeighlightedLines(for: cursorPosition.range) else {
            return
        }
        
        // TODO: Get indentation chars form settings

        textView.undoManager?.beginUndoGrouping()
        for lineIndex in lineIndexes {
            if inwards {
                indentInward(lineIndex: lineIndex)
            } else {
                indent(lineIndex: lineIndex)
            }
        }
        textView.undoManager?.endUndoGrouping()
    }

    private func getHeighlightedLines(for range: NSRange) -> [Int]? {
        guard let startLineInfo = textView.layoutManager.textLineForOffset(range.lowerBound) else {
            return nil
        }
        var lines: [Int] = [startLineInfo.index]

        guard let endLineInfo = textView.layoutManager.textLineForOffset(range.upperBound),
              endLineInfo.index != startLineInfo.index else {
            return lines
        }
        if endLineInfo.index == startLineInfo.index + 1 {
            lines.append(endLineInfo.index)
            return lines
        }

        return Array(startLineInfo.index...endLineInfo.index)
    }

    private func indent(lineIndex: Int) {
        guard let lineInfo = textView.layoutManager.textLineForIndex(lineIndex) else {
            return
        }

        textView.replaceCharacters(
                in: NSRange(location: lineInfo.range.lowerBound, length: 0),
                with: "  "
            )
    }

    private func indentInward(lineIndex: Int) {
        guard let lineInfo = textView.layoutManager.textLineForIndex(lineIndex) else {
            return
        }

        guard let lineContent = textView.textStorage.substring(from: lineInfo.range) else { return }

        // get first chars when spaces are enabled just the amount of spaces
        // if there is text in front count til the text

        // TODO: Remove hardcoded 4
        let removeSpacesCount = countLeadingSpacesUpTo(line: lineContent, maxCount: 4)
        guard removeSpacesCount != 0 else { return }

        textView.replaceCharacters(
            in: NSRange(location: lineInfo.range.lowerBound, length: removeSpacesCount),
            with: ""
        )
    }

    func countLeadingSpacesUpTo(line: String, maxCount: Int) -> Int {
        var count = 0

        for char in line {
            if char == " " {
                count += 1
            } else {
                break  // Stop as soon as a non-space character is encountered
            }

            // Stop early if we've counted the max number of spaces
            if count == maxCount {
                break
            }
        }

        return count
    }
}
