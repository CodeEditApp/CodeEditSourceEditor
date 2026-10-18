//
//  NSTextStorageSnapshotTests.swift
//  CodeEditSourceEditor
//

import Testing
import AppKit
@testable import CodeEditSourceEditor

/// Work that reads the text off the main thread needs a snapshot that edits leave alone. `string as NSString` is not
/// one: it is the live backing string.
struct NSTextStorageSnapshotTests {
    @Test
    func snapshotIsUnaffectedByLaterEdits() {
        let text = (0..<2_000).map { "line \($0)" }.joined(separator: "\n")
        let storage = NSTextStorage(string: text)
        let snapshot = storage.stringSnapshot
        let live = storage.string as NSString

        storage.replaceCharacters(in: NSRange(location: 10, length: 5), with: "edited")
        storage.replaceCharacters(in: NSRange(location: 0, length: 0), with: "prefix ")

        #expect(snapshot as String == text)
        #expect(storage.string.hasPrefix("prefix "))
        // The hazard the snapshot exists for: the bridged string changes with the storage.
        #expect(live.length == storage.length)
    }
}
