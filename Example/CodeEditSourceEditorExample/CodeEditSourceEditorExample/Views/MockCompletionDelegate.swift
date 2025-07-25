//
//  MockCompletionDelegate.swift
//  CodeEditSourceEditorExample
//
//  Created by Khan Winter on 7/22/25.
//

import SwiftUI
import CodeEditSourceEditor
import CodeEditTextView

private let text = [
    "Lorem",
    "ipsum",
    "dolor",
    "sit",
    "amet,",
    "consectetur",
    "adipiscing",
    "elit.",
    "Ut",
    "condimentum",
    "dictum",
    "malesuada.",
    "Praesent",
    "ut",
    "imperdiet",
    "nulla.",
    "Vivamus",
    "feugiat,",
    "ante",
    "non",
    "sagittis",
    "pellentesque,",
    "dui",
    "massa",
    "consequat",
    "odio,",
    "ac",
    "vestibulum",
    "augue",
    "erat",
    "et",
    "nunc."
]

class MockCompletionDelegate: CodeSuggestionDelegate, ObservableObject {
    class Suggestion: CodeSuggestionEntry {
        var label: String
        var detail: String?
        var pathComponents: [String]? { nil }
        var targetPosition: CursorPosition? { nil }
        var sourcePreview: String? { nil }
        var image: Image = Image(systemName: "dot.square.fill")
        var imageColor: Color = .gray
        var deprecated: Bool = false

        init(text: String) {
            self.label = text
        }
    }

    private func randomSuggestions(_ count: Int? = nil) -> [Suggestion] {
        let count = count ?? Int.random(in: 0..<20)
        var suggestions: [Suggestion] = []
        for _ in 0..<count {
            let randomString = (0..<Int.random(in: 1..<text.count)).map {
                text[$0]
            }.shuffled().joined(separator: " ")
            suggestions.append(Suggestion(text: randomString))
        }
        return suggestions
    }

    var moveCount = 0

    func completionSuggestionsRequested(
        textView: TextViewController,
        cursorPosition: CursorPosition
    ) async -> (windowPosition: CursorPosition, items: [CodeSuggestionEntry])? {
        try? await Task.sleep(for: .seconds(0.2))
        return (cursorPosition, randomSuggestions())
    }

    func completionOnCursorMove(
        textView: TextViewController,
        cursorPosition: CursorPosition
    ) -> [CodeSuggestionEntry]? {
        moveCount += 1
        switch moveCount {
        case 1:
            return randomSuggestions(2)
        case 2:
            return randomSuggestions(20)
        default:
            moveCount = 0
            return nil
        }
    }

    func completionWindowApplyCompletion(
        item: CodeSuggestionEntry,
        textView: TextViewController,
        cursorPosition: CursorPosition?
    ) {
        guard let suggestion = item as? Suggestion else {
            return
        }
        textView.textView.undoManager?.beginUndoGrouping()
        textView.textView.insertText(suggestion.label)
        textView.textView.undoManager?.endUndoGrouping()
    }
}
