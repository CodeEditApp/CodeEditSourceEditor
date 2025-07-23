//
//  MockCompletionDelegate.swift
//  CodeEditSourceEditorExample
//
//  Created by Khan Winter on 7/22/25.
//

import AppKit
import CodeEditSourceEditor
import CodeEditTextView

class MockCompletionDelegate: CodeSuggestionDelegate, ObservableObject {
    class Suggestion: CodeSuggestionEntry {
        let text: String
        var view: NSView {
            let view = NSTextField(string: text)
            view.isEditable = false
            view.isSelectable = false
            view.isBezeled = false
            view.isBordered = false
            view.backgroundColor = .clear
            view.textColor = .black
            return view
        }

        init(text: String) {
            self.text = text
        }
    }

    func completionSuggestionsRequested(
        textView: TextViewController,
        cursorPosition: CursorPosition
    ) async -> (windowPosition: CursorPosition, items: [CodeSuggestionEntry])? {
        try? await Task.sleep(for: .seconds(0.2))
        return (cursorPosition, [Suggestion(text: "Hello"), Suggestion(text: "World")])
    }
    
    func completionOnCursorMove(
        textView: TextViewController,
        cursorPosition: CursorPosition
    ) -> [CodeSuggestionEntry]? {
        if Bool.random() {
            [Suggestion(text: "Another one")]
        } else {
            nil
        }
    }

    func completionWindowApplyCompletion(
        item: CodeSuggestionEntry,
        textView: TextViewController,
        cursorPosition: CursorPosition
    ) {
        guard let suggestion = item as? Suggestion else {
            return
        }
        textView.textView.undoManager?.beginUndoGrouping()
        textView.textView.insertText(suggestion.text)
        textView.textView.undoManager?.endUndoGrouping()
    }
}
