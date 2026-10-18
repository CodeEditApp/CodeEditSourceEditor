//
//  NSTextStorage+Snapshot.swift
//  CodeEditSourceEditor
//

import AppKit

extension NSTextStorage {
    /// An immutable copy of the text, safe to read from any thread while the storage keeps changing.
    ///
    /// `string as NSString` is the live backing string, which edits mutate in place. Its copy is O(1): the backing
    /// string is copy-on-write.
    var stringSnapshot: NSString {
        let live = string as NSString
        return live.copy() as? NSString ?? NSString(string: live)
    }
}
