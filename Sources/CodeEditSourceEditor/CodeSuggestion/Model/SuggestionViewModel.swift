//
//  SuggestionViewModel.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 7/22/25.
//

import AppKit

final class SuggestionViewModel: ObservableObject {
    /// The items to be displayed in the window
    @Published var items: [CodeSuggestionEntry] = []
    var itemsRequestTask: Task<Void, Never>?
    weak var activeTextView: TextViewController?

    var delegate: CodeSuggestionDelegate? {
        activeTextView?.completionDelegate
    }

    func showCompletions(
        textView: TextViewController,
        delegate: CodeSuggestionDelegate,
        cursorPosition: CursorPosition,
        showWindowOnParent: @escaping @MainActor (NSWindow, NSRect) -> Void
    ) {
        self.activeTextView = nil
        itemsRequestTask?.cancel()

        guard let targetParentWindow = textView.view.window else { return }

        self.activeTextView = textView
        itemsRequestTask = Task {
            defer { itemsRequestTask = nil }

            do {
                guard let completionItems = await delegate.completionSuggestionsRequested(
                    textView: textView,
                    cursorPosition: cursorPosition
                ) else {
                    return
                }

                try Task.checkCancellation()
                try await MainActor.run {
                    try Task.checkCancellation()

                    guard let cursorPosition = textView.resolveCursorPosition(completionItems.windowPosition),
                          let cursorRect = textView.textView.layoutManager.rectForOffset(
                            cursorPosition.range.location
                          ),
                          let cursorRect = textView.view.window?.convertToScreen(
                            textView.textView.convert(cursorRect, to: nil)
                          ) else {
                        return
                    }

                    self.items = completionItems.items
                    showWindowOnParent(targetParentWindow, cursorRect)
                }
            } catch {
                return
            }
        }
    }

    func cursorsUpdated(
        textView: TextViewController,
        delegate: CodeSuggestionDelegate,
        position: CursorPosition,
        close: () -> Void
    ) {
        guard itemsRequestTask == nil else { return }

        if activeTextView !== textView {
            close()
            return
        }

        guard let newItems = delegate.completionOnCursorMove(
            textView: textView,
            cursorPosition: position
        ),
              !newItems.isEmpty else {
            close()
            return
        }

        items = newItems
    }

    func didSelect(item: CodeSuggestionEntry) {
        delegate?.completionWindowDidSelect(item: item)
    }

    func applySelectedItem(item: CodeSuggestionEntry, window: NSWindow?) {
        guard let activeTextView,
              let cursorPosition = activeTextView.cursorPositions.first else {
            return
        }
        self.delegate?.completionWindowApplyCompletion(
            item: item,
            textView: activeTextView,
            cursorPosition: cursorPosition
        )
        window?.close()
    }

    func willClose() {
        items.removeAll()
        activeTextView = nil
    }
}
