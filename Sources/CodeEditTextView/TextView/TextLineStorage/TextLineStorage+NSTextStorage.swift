//
//  File.swift
//  
//
//  Created by Khan Winter on 8/21/23.
//

import AppKit

extension TextLineStorage where Data == TextLine {
    /// Builds the line storage object from the given `NSTextStorage`.
    /// - Parameters:
    ///   - textStorage: The text storage object to use.
    ///   - estimatedLineHeight: The estimated height of each individual line.
    func buildFromTextStorage(_ textStorage: NSTextStorage, estimatedLineHeight: CGFloat) {
        func getNextLine(startingAt location: Int) -> NSRange? {
            let range = NSRange(location: location, length: 0)
            var end: Int = NSNotFound
            var contentsEnd: Int = NSNotFound
            (textStorage.string as NSString).getLineStart(nil, end: &end, contentsEnd: &contentsEnd, for: range)
            if end != NSNotFound && contentsEnd != NSNotFound && end != contentsEnd {
                return NSRange(location: contentsEnd, length: end - contentsEnd)
            } else {
                return nil
            }
        }

        var index = 0
        var lines: [BuildItem] = []
        while let range = getNextLine(startingAt: index) {
            lines.append(
                BuildItem(
                    data: TextLine(),
                    length: range.max - index
                )
            )
            index = NSMaxRange(range)
        }
        // Create the last line
        if textStorage.length - index > 0 {
            lines.append(
                BuildItem(
                    data: TextLine(),
                    length: textStorage.length - index
                )
            )
        }

        // Use an efficient tree building algorithm rather than adding lines sequentially
        self.build(from: lines, estimatedLineHeight: estimatedLineHeight)
    }
}
