//
//  File.swift
//  
//
//  Created by Khan Winter on 8/21/23.
//

import AppKit
import Common

extension TextLineStorage where Data == TextLine {
    /// Builds the line storage object from the given `NSTextStorage`.
    /// - Parameters:
    ///   - textStorage: The text storage object to use.
    ///   - estimatedLineHeight: The estimated height of each individual line.
    func buildFromTextStorage(_ textStorage: NSTextStorage, estimatedLineHeight: CGFloat) {
        var index = 0
        var lines: [BuildItem] = []
        while let range = textStorage.getNextLine(startingAt: index) {
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
