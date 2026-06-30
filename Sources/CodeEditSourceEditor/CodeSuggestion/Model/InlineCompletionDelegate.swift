//
//  InlineCompletionDelegate.swift
//  CodeEditSourceEditor
//
//  Created by anxkhn on 6/29/26.
//

@MainActor
public protocol InlineCompletionDelegate: AnyObject {
    /// Requests inline completion items for the given cursor position.
    ///
    /// Called after the user types, debounced by the controller. Return an empty array to display nothing.
    func inlineCompletionsRequested(
        textView: TextViewController,
        cursorPosition: CursorPosition
    ) async -> [InlineCompletionItem]

    /// Called when an item begins displaying as ghost text.
    func inlineCompletionDidShow(item: InlineCompletionItem)

    /// Called when an item is accepted and inserted into the document.
    func inlineCompletionDidAccept(item: InlineCompletionItem)

    /// Called when a displayed item is dismissed without being accepted.
    func inlineCompletionDidDismiss(item: InlineCompletionItem)
}

public extension InlineCompletionDelegate {
    func inlineCompletionDidShow(item: InlineCompletionItem) { }
    func inlineCompletionDidAccept(item: InlineCompletionItem) { }
    func inlineCompletionDidDismiss(item: InlineCompletionItem) { }
}
