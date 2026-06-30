//
//  InlineCompletionTriggerModel.swift
//  CodeEditSourceEditor
//
//  Created by anxkhn on 6/29/26.
//

import AppKit
import CodeEditTextView
import TextStory

/// Triggers an inline completion (ghost text) request when the user edits text.
/// Designed to be called in the ``TextViewDelegate``'s didReplaceCharacters method.
///
/// Mirrors ``SuggestionTriggerCharacterModel``: it lives as effectively a text view delegate so that both the text
/// contents and the caret are up-to-date when it runs. Any mutation clears the current ghost text before a new
/// request is debounced. Ghost text and the existing suggestion popup are mutually exclusive, so requests are skipped
/// while ``SuggestionController`` is visible.
@MainActor
final class InlineCompletionTriggerModel {
    weak var controller: TextViewController?

    func textView(_ textView: TextView, didReplaceContentsIn range: NSRange, with string: String) {
        guard let controller, controller.inlineCompletionDelegate != nil else {
            return
        }

        // Any edit invalidates the currently displayed ghost text.
        controller.dismissInlineSuggestion()

        // Ghost text and the existing suggestion popup are mutually exclusive.
        guard !SuggestionController.shared.isVisible else {
            return
        }

        let mutation = TextMutation(
            string: string,
            range: range,
            limit: textView.textStorage.length
        )

        // Only request after an insertion (typing), not after a deletion.
        guard mutation.delta > 0 else {
            return
        }

        controller.requestInlineSuggestion()
    }
}
