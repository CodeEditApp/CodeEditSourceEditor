//
//  TextViewController+IndentLines.swift
//
//
//  Created by Ludwig, Tom on 11.09.24.
//

import CodeEditTextView
import AppKit

extension TextViewController {
    /// Handels indentation and unindentation
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
        for cursorPosition in self.cursorPositions {
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

    private func getHighlightedLines(for range: NSRange) -> [Int]? {
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

    private func countLeadingSpacesUpTo(line: String, maxCount: Int) -> Int {
        // Count leading spaces using prefix and `filter`
        return line.prefix(maxCount).filter { $0 == " " }.count
    }
}
