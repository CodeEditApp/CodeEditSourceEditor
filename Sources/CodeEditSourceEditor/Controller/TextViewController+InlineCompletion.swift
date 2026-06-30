//
//  TextViewController+InlineCompletion.swift
//  CodeEditSourceEditor
//
//  Created by anxkhn on 6/29/26.
//

import AppKit
import CodeEditTextView

public extension TextViewController {
    /// The debounce interval applied before an inline completion request is sent to the delegate.
    private static var inlineCompletionDebounce: Duration { .milliseconds(200) }

    /// Requests inline completion items from the ``inlineCompletionDelegate``.
    ///
    /// Debounced with a single in-flight cancellable task. Each call cancels any pending request. Requests are skipped
    /// while the suggestion popup is visible, so ghost text and the popup never appear at the same time.
    func requestInlineSuggestion() {
        inlineCompletionTask?.cancel()
        inlineCompletionTask = nil

        guard let delegate = inlineCompletionDelegate,
              !SuggestionController.shared.isVisible,
              let selectedRange = textView.selectionManager.textSelections.first?.range,
              let cursorPosition = resolveCursorPosition(CursorPosition(range: selectedRange)) else {
            return
        }

        inlineCompletionTask = Task { [weak self] in
            do {
                try await Task.sleep(for: Self.inlineCompletionDebounce)
                try Task.checkCancellation()

                guard let self else { return }

                let items = await delegate.inlineCompletionsRequested(
                    textView: self,
                    cursorPosition: cursorPosition
                )

                try Task.checkCancellation()
                guard !items.isEmpty, !SuggestionController.shared.isVisible else {
                    return
                }

                self.setInlineSuggestions(items)
            } catch {
                return
            }
        }
    }

    /// Renders the given inline completion items as ghost text, displaying the item at `selectedIndex`.
    ///
    /// Stores the items and renders the selected item's ``InlineCompletionItem/insertText`` as ghost text anchored at
    /// the caret. Notifies the delegate via ``InlineCompletionDelegate/inlineCompletionDidShow(item:)``.
    /// - Parameters:
    ///   - items: The items to make available. Passing an empty array is a no-op.
    ///   - selectedIndex: The index of the item to display. Clamped to a valid index.
    func setInlineSuggestions(_ items: [InlineCompletionItem], selectedIndex: Int = 0) {
        guard !items.isEmpty, !SuggestionController.shared.isVisible else {
            return
        }

        inlineSuggestionItems = items
        inlineSuggestionSelectedIndex = min(max(0, selectedIndex), items.count - 1)
        let item = items[inlineSuggestionSelectedIndex]
        activeInlineSuggestion = item

        let offset = textView.selectionManager.textSelections.first?.range.location ?? item.range.location
        inlineSuggestionAnchor = offset
        textView.setInlineSuggestion(item.insertText, at: offset)

        inlineCompletionDelegate?.inlineCompletionDidShow(item: item)
    }

    /// Accepts the active inline suggestion, inserting its text into the document.
    ///
    /// Replaces the characters in the item's range with its ``InlineCompletionItem/insertText``, clears the ghost
    /// text, and notifies the delegate.
    /// - Returns: `true` if a suggestion was accepted, otherwise `false`.
    @discardableResult
    func acceptInlineSuggestion() -> Bool {
        guard let item = activeInlineSuggestion else {
            return false
        }

        // Clear state before mutating so the edit doesn't re-enter this suggestion's lifecycle.
        clearInlineSuggestionState()
        textView.clearInlineSuggestion()
        textView.replaceCharacters(in: item.range, with: item.insertText)

        inlineCompletionDelegate?.inlineCompletionDidAccept(item: item)
        return true
    }

    /// Cycles to the next inline suggestion and re-renders it.
    func selectNextInlineSuggestion() {
        guard !inlineSuggestionItems.isEmpty else { return }
        let next = (inlineSuggestionSelectedIndex + 1) % inlineSuggestionItems.count
        setInlineSuggestions(inlineSuggestionItems, selectedIndex: next)
    }

    /// Cycles to the previous inline suggestion and re-renders it.
    func selectPreviousInlineSuggestion() {
        guard !inlineSuggestionItems.isEmpty else { return }
        let count = inlineSuggestionItems.count
        let previous = (inlineSuggestionSelectedIndex - 1 + count) % count
        setInlineSuggestions(inlineSuggestionItems, selectedIndex: previous)
    }

    /// Dismisses the active inline suggestion without inserting it.
    ///
    /// Clears the ghost text and notifies the delegate.
    /// - Returns: `true` if a suggestion was dismissed, otherwise `false`.
    @discardableResult
    func dismissInlineSuggestion() -> Bool {
        guard let item = activeInlineSuggestion else {
            return false
        }

        clearInlineSuggestionState()
        textView.clearInlineSuggestion()

        inlineCompletionDelegate?.inlineCompletionDidDismiss(item: item)
        return true
    }

    /// Resets all stored inline suggestion state and cancels any in-flight request.
    private func clearInlineSuggestionState() {
        inlineCompletionTask?.cancel()
        inlineCompletionTask = nil
        activeInlineSuggestion = nil
        inlineSuggestionItems = []
        inlineSuggestionSelectedIndex = 0
        inlineSuggestionAnchor = nil
    }
}
