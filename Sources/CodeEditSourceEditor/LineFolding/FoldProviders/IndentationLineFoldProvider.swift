//
//  IndentationLineFoldProvider.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 5/8/25.
//

import AppKit
import CodeEditTextView

final class IndentationLineFoldProvider: LineFoldProvider {
    func foldLevelAtLine(_ lineNumber: Int, substring: NSString) -> Int? {
        for idx in 0..<substring.length {
            let character = UnicodeScalar(substring.character(at: idx))
            if character?.properties.isWhitespace == false {
                return idx
            }
        }
        return nil
    }
}
