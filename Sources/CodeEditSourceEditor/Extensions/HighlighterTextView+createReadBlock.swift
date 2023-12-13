//
//  HighlighterTextView+createReadBlock.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 5/20/23.
//

import Foundation
import SwiftTreeSitter

extension HighlighterTextView {
    func createReadBlock() -> Parser.ReadBlock {
        return { byteOffset, _ in
            let limit = self.documentRange.length
            let location = byteOffset / 2
            let end = min(location + (1024), limit)
            if location > end {
                // Ignore and return nothing, tree-sitter's internal tree can be incorrect in some situations.
                return nil
            }
            let range = NSRange(location..<end)
            return self.stringForRange(range)?.data(using: String.nativeUTF16Encoding)
        }
    }
}
