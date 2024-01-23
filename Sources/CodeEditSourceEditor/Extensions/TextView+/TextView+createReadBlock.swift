//
//  HighlighterTextView+createReadBlock.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 5/20/23.
//

import Foundation
import CodeEditTextView
import SwiftTreeSitter

extension TextView {
    func createReadBlock() -> Parser.ReadBlock {
        return { [weak self] byteOffset, _ in
            let limit = self?.documentRange.length ?? 0
            let location = byteOffset / 2
            let end = min(location + (1024), limit)
            if location > end || self == nil {
                // Ignore and return nothing, tree-sitter's internal tree can be incorrect in some situations.
                return nil
            }
            let range = NSRange(location..<end)
            return self?.stringForRange(range)?.data(using: String.nativeUTF16Encoding)
        }
    }

    func createReadCallback() -> SwiftTreeSitter.Predicate.TextProvider {
        return { [weak self] range, _ in
            return self?.stringForRange(range)
        }
    }
}
