//
//  InlineCompletionItem.swift
//  CodeEditSourceEditor
//
//  Created by anxkhn on 6/29/26.
//

import Foundation

/// Represents a single inline completion (ghost text) suggestion.
///
/// An item is rendered as ghost text anchored at the caret. When accepted, the ``insertText`` replaces the characters
/// in ``range``. An empty ``range`` represents a pure insertion at the cursor.
public struct InlineCompletionItem: Sendable, Identifiable {
    /// A stable identifier for the item.
    public let id: UUID

    /// The text to insert when the item is accepted. This is also the text rendered as ghost text.
    public let insertText: String

    /// The range the ``insertText`` replaces when accepted. An empty range is a pure insertion at the cursor.
    public let range: NSRange

    /// Create an inline completion item.
    /// - Parameters:
    ///   - id: A stable identifier for the item. Defaults to a new `UUID`.
    ///   - insertText: The text to insert when accepted, and the text rendered as ghost text.
    ///   - range: The range replaced on acceptance. An empty range is a pure insertion at the cursor.
    public init(id: UUID = UUID(), insertText: String, range: NSRange) {
        self.id = id
        self.insertText = insertText
        self.range = range
    }
}
