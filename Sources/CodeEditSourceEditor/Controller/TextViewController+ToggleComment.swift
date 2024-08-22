//
//  TextViewController+Shortcuts.swift
//  CodeEditSourceEditor
//
//  Created by Sophia Hooley on 4/21/24.
//

import CodeEditTextView
import AppKit

extension TextViewController {
    /// Method called when CMD + / key sequence is recognized.
    /// Comments or uncomments the cursor's current line(s) of code.
    public func handleCommandSlash() {
        guard let cursorPosition = cursorPositions.first else { return }
        let lineNumbers = lineNumbers(from: cursorPosition.range, in: text)

        // Determine if we need to insert or remove comment chars.
        let insertChars = !linesHaveCommentChars(for: lineNumbers)

        for lineNumber in lineNumbers {
            toggleComment(on: lineNumber, insertChars: insertChars)
        }
    }

    /// Checks if all lines have comment characters at the beginning.
    /// - Parameter lines: An array of line numbers to check.
    /// - Returns: `true` if any line does not have comment chars, otherwise `false`.
    func linesHaveCommentChars(for lines: [Int]) -> Bool {
        let commentChars = language.lineCommentString.isEmpty
        ? language.rangeCommentStrings.0
        : language.lineCommentString

        for line in lines where !checkCharsAtBeginningOfLine(chars: commentChars, for: line) {
            return false
        }
        return true
    }

    /// Checks if the specified characters exist at the beginning of a line.
    /// - Parameters:
    ///   - chars: The characters to check for.
    ///   - line: The line number (1-indexed).
    /// - Returns: `true` if the characters are found, otherwise `false`.
    func checkCharsAtBeginningOfLine(chars: String, for line: Int) -> Bool {
        guard let lineInfo = textView.layoutManager.textLineForIndex(line - 1),
              let lineString = textView.textStorage.substring(from: lineInfo.range) else {
            return false
        }

        // Trims leading and trailing whitespace, then checks if the line starts with the specified characters.
        return lineString.trimmingCharacters(in: .whitespacesAndNewlines).starts(with: chars)
    }

    /// Calculates the start and end line numbers for a given range.
    /// - Parameters:
    ///   - range: The text range.
    ///   - text: The full text string.
    /// - Returns: An array of line numbers.
    func lineNumbers(from range: NSRange, in text: String) -> [Int] {
        let startLine = lineNumber(at: range.location, in: text)
        let endLine = lineNumber(at: NSMaxRange(range), in: text)

        // Ensure startLine is not greater than endLine
        let validStartLine = min(startLine, endLine)
        let validEndLine = max(startLine, endLine)

        return Array(validStartLine...validEndLine)
    }

    /// Calculates the line number at a specific position.
    /// - Parameters:
    ///   - position: The character position in the text.
    ///   - text: The full text string.
    /// - Returns: The line number (1-indexed).
    func lineNumber(at position: Int, in text: String) -> Int {
        let nsText = text as NSString
        let substring = nsText.substring(to: position)
        return substring.components(separatedBy: "\n").count
    }

    /// Toggles the comment on or off for a given line.
    /// - Parameters:
    ///   - line: The line number (1-indexed).
    ///   - insertChars: `true` to insert the comment chars, `false` to remove them.
    private func toggleComment(on line: Int, insertChars: Bool) {
        if !language.lineCommentString.isEmpty {
            toggleCharsAtBeginningOfLine(chars: language.lineCommentString, for: line, insertChars: insertChars)
        } else {
            let (openComment, closeComment) = language.rangeCommentStrings
            toggleCharsAtEndOfLine(chars: closeComment, for: line, insertChars: insertChars)
            toggleCharsAtBeginningOfLine(chars: openComment, for: line, insertChars: insertChars)
        }
    }

    /// Toggles the specified string of characters at the beginning of a line.
    /// - Parameters:
    ///   - chars: The characters to toggle.
    ///   - lineNumber: The line number (1-indexed).
    ///   - insertChars: `true` to insert the chars, `false` to remove them.
    private func toggleCharsAtBeginningOfLine(chars: String, for lineNumber: Int, insertChars: Bool) {
        guard let lineInfo = textView.layoutManager.textLineForIndex(lineNumber - 1),
              let lineString = textView.textStorage.substring(from: lineInfo.range) else {
            return
        }

        // Execute the function before calculating the index of the first non-whitespace character
        // and the number of leading whitespace characters.
        if insertChars {
            textView.replaceCharacters(in: NSRange(location: lineInfo.range.location, length: 0), with: chars)
            return
        }

        let firstNonWhitespaceIndex = lineString.firstIndex(where: { !$0.isWhitespace }) ?? lineString.startIndex
        let numWhitespaceChars = lineString.distance(from: lineString.startIndex, to: firstNonWhitespaceIndex)

        if !insertChars {
            textView.replaceCharacters(
                in: NSRange(location: lineInfo.range.location + numWhitespaceChars, length: chars.count),
                with: ""
            )
        }
    }

    /// Toggles the specified string of characters at the end of a line.
    /// - Parameters:
    ///   - chars: The characters to toggle.
    ///   - lineNumber: The line number (1-indexed).
    ///   - insertChars: `true` to insert the chars, `false` to remove them.
    private func toggleCharsAtEndOfLine(chars: String, for lineNumber: Int, insertChars: Bool) {
        guard let lineInfo = textView.layoutManager.textLineForIndex(lineNumber - 1), !lineInfo.range.isEmpty else {
            return
        }

        let lineLastCharIndex = lineInfo.range.location + lineInfo.range.length
        let closeCommentRange = NSRange(location: lineLastCharIndex - chars.count, length: chars.count)

        if insertChars {
            textView.replaceCharacters(in: NSRange(location: lineLastCharIndex, length: 0), with: chars)
        } else {
            textView.replaceCharacters(in: closeCommentRange, with: "")
        }
    }
}
