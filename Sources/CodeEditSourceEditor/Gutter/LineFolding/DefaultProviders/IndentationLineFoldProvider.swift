//
//  IndentationLineFoldProvider.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 5/8/25.
//

import AppKit
import CodeEditTextView

final class IndentationLineFoldProvider: LineFoldProvider {
    func foldLevelAtLine(_ lineNumber: Int, layoutManager: TextLayoutManager, textStorage: NSTextStorage) -> Int? {
        guard let linePosition = layoutManager.textLineForIndex(lineNumber),
              let indentLevel = indentLevelForPosition(linePosition, textStorage: textStorage) else {
            return nil
        }

        return indentLevel
    }

    private func indentLevelForPosition(
        _ position: TextLineStorage<TextLine>.TextLinePosition,
        textStorage: NSTextStorage
    ) -> Int? {
        guard let substring = textStorage.substring(from: position.range) else {
            return nil
        }

        return substring.utf16 // Keep NSString units
            .enumerated()
            .first(where: { UnicodeScalar($0.element)?.properties.isWhitespace != true })?
            .offset
    }
}
