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
        for cursorPosition in self.cursorPositions {
            // get lineindex, i.e line-numbers+1
            guard let lineIndexes = getHeighlightedLines(for: cursorPosition.range) else { return }

            // TODO: Get indentation chars and count form settings
            let spaceCount = 2
            let indentationChars = String(repeating: " ", count: spaceCount)

            textView.undoManager?.beginUndoGrouping()
            for lineIndex in lineIndexes {
                if inwards {
                    indentInward(lineIndex: lineIndex, spacesCount: indentationChars.count)
                } else {
                    indent(lineIndex: lineIndex, indentationCharacters: indentationChars)
                }
            }
            textView.undoManager?.endUndoGrouping()
        }
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

    private func indent(lineIndex: Int, indentationCharacters: String) {
        guard let lineInfo = textView.layoutManager.textLineForIndex(lineIndex) else {
            return
        }

        textView.replaceCharacters(
                in: NSRange(location: lineInfo.range.lowerBound, length: 0),
                with: indentationCharacters
            )
    }

    private func indentInward(lineIndex: Int, spacesCount: Int) {
        guard let lineInfo = textView.layoutManager.textLineForIndex(lineIndex) else {
            return
        }

        guard let lineContent = textView.textStorage.substring(from: lineInfo.range) else { return }

        // Count spaces until the required amount.
        // E.g. if 4 are needed but only 3 are present, remove only those 3.
        let removeSpacesCount = countLeadingSpacesUpTo(line: lineContent, maxCount: spacesCount)
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
