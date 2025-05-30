//
//  IndentationLineFoldProvider.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 5/8/25.
//

import AppKit
import CodeEditTextView

final class IndentationLineFoldProvider: LineFoldProvider {
    func indentLevelAtLine(substring: NSString) -> Int? {
        for idx in 0..<substring.length {
            let character = UnicodeScalar(substring.character(at: idx))
            if character?.properties.isWhitespace == false {
                return idx
            }
        }
        return nil
    }

    func foldLevelAtLine(
        lineNumber: Int,
        lineRange: NSRange,
        previousDepth: Int,
        text: NSTextStorage
    ) -> [LineFoldProviderLineInfo] {
        guard let leadingIndent = text.leadingRange(in: lineRange, within: .whitespacesWithoutNewlines)?.length,
              leadingIndent != lineRange.length else {
            return []
        }

        var foldIndicators: [LineFoldProviderLineInfo] = []

        if leadingIndent < previousDepth {
            // End the fold at the start of whitespace
            foldIndicators.append(.endFold(rangeEnd: lineRange.location + leadingIndent, newDepth: leadingIndent))
        }

        // Check if the next line has more indent
        let maxRange = NSRange(start: lineRange.max, end: text.length)
        guard let nextIndent = text.leadingRange(in: maxRange, within: .whitespacesWithoutNewlines)?.length,
              nextIndent > 0 else {
            return foldIndicators
        }

        if nextIndent > leadingIndent, let trailingWhitespace = text.trailingWhitespaceRange(in: lineRange) {
            foldIndicators.append(.startFold(rangeStart: trailingWhitespace.location, newDepth: nextIndent))
        }

        return foldIndicators
    }
}
