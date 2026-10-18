//
//  TreeSitterTextSnapshot.swift
//  CodeEditSourceEditor
//

import AppKit
import SwiftTreeSitter

/// An immutable copy of a document's text, with the tree-sitter callbacks that read it from any thread.
///
/// Taking one is O(1) (see ``NSTextStorage/stringSnapshot``). Take it on the main thread, when the text matches the
/// edits the parse will apply.
struct TreeSitterTextSnapshot {
    let text: NSString

    init(textStorage: NSTextStorage) {
        self.text = textStorage.stringSnapshot
    }

    /// Reads up to ``TreeSitterClient/Constants/charsToReadInBlock`` UTF-16 units at a byte offset.
    var readBlock: Parser.ReadBlock {
        let text = text
        let length = text.length
        return { byteOffset, _ in
            let location = byteOffset / 2
            let end = min(location + TreeSitterClient.Constants.charsToReadInBlock, length)
            guard location < end else { return nil }
            // Raw code units: a block boundary can split a surrogate pair, which a `String` round trip would lose.
            var data = Data(count: (end - location) * MemoryLayout<unichar>.stride)
            data.withUnsafeMutableBytes { buffer in
                text.getCharacters(
                    buffer.baseAddress!.assumingMemoryBound(to: unichar.self),
                    range: NSRange(location: location, length: end - location)
                )
            }
            return data
        }
    }

    /// Reads the text of a range, for query predicates and injections.
    var readCallback: SwiftTreeSitter.Predicate.TextProvider {
        let text = text
        return { range, _ in
            guard range.location >= 0, NSMaxRange(range) <= text.length else { return nil }
            return text.substring(with: range)
        }
    }
}
