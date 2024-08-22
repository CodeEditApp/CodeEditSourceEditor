//
//  TextViewController+Shortcuts.swift
//  CodeEditSourceEditor
//
//  Created by Sophia Hooley on 4/21/24.
//

import CodeEditTextView
import AppKit

extension TextViewController {
    /// Method called when CMD + / key sequence recognized, comments cursor's current line of code
    public func commandSlashCalled() {
        guard let cursorPosition = cursorPositions.first else { return }
        let lineNumbers = lineNumbers(from: cursorPosition.range, in: text)

        for lineNumber in lineNumbers {
            toggleComment(on: lineNumber)
        }
    }

    // Calculate the start and end line numbers for a given range
    func lineNumbers(from range: NSRange, in text: String) -> [Int] {
        let startLine = lineNumber(at: range.location, in: text)
        let endLine = lineNumber(at: NSMaxRange(range), in: text)
        return Array(startLine...endLine)
    }

    // Calculate the line number at a specific position
    func lineNumber(at position: Int, in text: String) -> Int {
        let nsText = text as NSString
        let substring = nsText.substring(to: position)
        return substring.components(separatedBy: "\n").count
    }

    private func toggleComment(on line: Int) {
        // Many languages require a character sequence at the beginning of the line to comment the line.
        // (ex. python #, C++ //)
        // If such a sequence exists, we will insert that sequence at the beginning of the line
        if !language.lineCommentString.isEmpty {
            toggleCharsAtBeginningOfLine(chars: language.lineCommentString, for: line)
        } else {
            // In other cases, languages require a character sequence 
            // at beginning and end of a line, aka a range comment (Ex. HTML <!--line here -->)
            // We treat the line as a one-line range to comment it
            // out using rangeCommentStrings on both sides of the line
            let (openComment, closeComment) = language.rangeCommentStrings
            toggleCharsAtEndOfLine(chars: closeComment, for: line)
            toggleCharsAtBeginningOfLine(chars: openComment, for: line)
        }
    }

    ///  Toggles comment string at the beginning of a specified line (lineNumber is 1-indexed)
    private func toggleCharsAtBeginningOfLine(chars: String, for lineNumber: Int) {
        guard let lineInfo = textView.layoutManager.textLineForIndex(lineNumber - 1),
              let lineString = textView.textStorage.substring(from: lineInfo.range) else {
            return
        }
        let firstNonWhiteSpaceCharIndex = lineString.firstIndex(where: { !$0.isWhitespace }) ?? lineString.startIndex
        let numWhitespaceChars = lineString.distance(from: lineString.startIndex, to: firstNonWhiteSpaceCharIndex)
        let firstCharsInLine = lineString.suffix(from: firstNonWhiteSpaceCharIndex).prefix(chars.count)
        // toggle comment off
        if firstCharsInLine == chars {
            textView.replaceCharacters(
                in: NSRange(location: lineInfo.range.location + numWhitespaceChars, length: chars.count),
                with: ""
            )
        } else {
            // toggle comment on
            textView.replaceCharacters(
                in: NSRange(location: lineInfo.range.location, length: 0),
                with: chars
            )
        }
    }

    ///  Toggles a specific string of characters at the end of a specified line. (lineNumber is 1-indexed)
    private func toggleCharsAtEndOfLine(chars: String, for lineNumber: Int) {
        guard let lineInfo = textView.layoutManager.textLineForIndex(lineNumber - 1), !lineInfo.range.isEmpty else {
            return
        }
        let lineLastCharIndex = lineInfo.range.location + lineInfo.range.length - 1
        let closeCommentLength = chars.count
        let closeCommentRange = NSRange(
            location: lineLastCharIndex - closeCommentLength,
            length: closeCommentLength
        )
        let lastCharsInLine = textView.textStorage.substring(from: closeCommentRange)
        // toggle comment off
        if lastCharsInLine == chars {
            textView.replaceCharacters(
                in: NSRange(location: lineLastCharIndex - closeCommentLength, length: closeCommentLength),
                with: ""
            )
        } else {
            // toggle comment on
            textView.replaceCharacters(in: NSRange(location: lineLastCharIndex, length: 0), with: chars)
        }
    }
}
