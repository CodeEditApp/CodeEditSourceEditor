//
//  TextViewController+IndentLines.swift
//  CodeEditTextView
//
//  Created by Ludwig, Tom on 11.09.24.
//

import AppKit
import CodeEditTextView

extension TextViewController {
    /// Handles indentation and unindentation
    ///
    /// Handles the indentation of lines in the text view based on the current indentation option.
    ///
    /// This function assumes that the document is formatted according to the current selected indentation option.
    /// It will not indent a tab character if spaces are selected, and vice versa. Ensure that the document is
    /// properly formatted before invoking this function.
    ///
    /// - Parameter inwards: A Boolean flag indicating whether to outdent (default is `false`).
    public func handleIndent(inwards: Bool = false) {
        let indentationChars: String = indentOption.stringValue
        guard !cursorPositions.isEmpty else { return }

        textView.undoManager?.beginUndoGrouping()
        for cursorPosition in self.cursorPositions.reversed() {
            // get lineindex, i.e line-numbers+1
            guard let lineIndexes = getHighlightedLines(for: cursorPosition.range) else { continue }

            for lineIndex in lineIndexes {
                adjustIndentation(
                    lineIndex: lineIndex,
                    indentationChars: indentationChars,
                    inwards: inwards
                )
            }
        }
        textView.undoManager?.endUndoGrouping()
    }

    /// This method is used to handle tabs appropriately when multiple lines are selected,
    /// allowing normal use of tabs.
    ///
    /// - Returns: A Boolean value indicating whether multiple lines are highlighted.
    func multipleLinesHighlighted() -> Bool {
        for cursorPosition in self.cursorPositions {
            if let startLineInfo = textView.layoutManager.textLineForOffset(cursorPosition.range.lowerBound),
               let endLineInfo = textView.layoutManager.textLineForOffset(cursorPosition.range.upperBound),
               startLineInfo.index != endLineInfo.index {
                return true
            }
        }
        return false
    }

    private func getHighlightedLines(for range: NSRange) -> ClosedRange<Int>? {
        guard let startLineInfo = textView.layoutManager.textLineForOffset(range.lowerBound) else {
            return nil
        }

        guard let endLineInfo = textView.layoutManager.textLineForOffset(range.upperBound),
              endLineInfo.index != startLineInfo.index else {
            return startLineInfo.index...startLineInfo.index
        }

        return startLineInfo.index...endLineInfo.index
    }

    private func adjustIndentation(lineIndex: Int, indentationChars: String, inwards: Bool) {
        guard let lineInfo = textView.layoutManager.textLineForIndex(lineIndex) else { return }

        if inwards {
            if indentOption != .tab {
                removeLeadingSpaces(lineInfo: lineInfo, spaceCount: indentationChars.count)
            } else {
                removeLeadingTab(lineInfo: lineInfo)
            }
        } else {
            addIndentation(lineInfo: lineInfo, indentationChars: indentationChars)
        }
    }

    private func addIndentation(
        lineInfo: TextLineStorage<TextLine>.TextLinePosition,
        indentationChars: String
    ) {
        textView.replaceCharacters(
            in: NSRange(location: lineInfo.range.lowerBound, length: 0),
            with: indentationChars
        )
    }

    private func removeLeadingSpaces(
        lineInfo: TextLineStorage<TextLine>.TextLinePosition,
        spaceCount: Int
    ) {
        guard let lineContent = textView.textStorage.substring(from: lineInfo.range) else { return }

        let removeSpacesCount = countLeadingSpacesUpTo(line: lineContent, maxCount: spaceCount)

        guard removeSpacesCount > 0 else { return }

        textView.replaceCharacters(
            in: NSRange(location: lineInfo.range.lowerBound, length: removeSpacesCount),
            with: ""
        )
    }

    private func removeLeadingTab(lineInfo: TextLineStorage<TextLine>.TextLinePosition) {
        guard let lineContent = textView.textStorage.substring(from: lineInfo.range) else {
            return
        }

        if lineContent.first == "\t" {
            textView.replaceCharacters(
                in: NSRange(location: lineInfo.range.lowerBound, length: 1),
                with: ""
            )
        }
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
