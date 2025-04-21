//
//  FindPanelViewModel+Replace.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 4/18/25.
//

import Foundation
import CodeEditTextView

extension FindPanelViewModel {
    func replace(all: Bool) {
        guard let target = target,
              let currentFindMatchIndex,
              !findMatches.isEmpty,
              let textViewController = target as? TextViewController else {
            return
        }

        if all {
            textViewController.textView.undoManager?.beginUndoGrouping()
            textViewController.textView.textStorage.beginEditing()

            var sortedMatches = findMatches.sorted(by: { $0.location < $1.location })
            for (idx, _) in sortedMatches.enumerated().reversed() {
                replaceMatch(index: idx, target: target, textView: textViewController.textView, matches: &sortedMatches)
            }

            textViewController.textView.textStorage.endEditing()
            textViewController.textView.undoManager?.endUndoGrouping()

            if let lastMatch = sortedMatches.last {
                target.setCursorPositions(
                    [CursorPosition(range: NSRange(location: lastMatch.location, length: 0))],
                    scrollToVisible: true
                )
            }

            updateMatches([])
        } else {
            replaceMatch(
                index: currentFindMatchIndex,
                target: target,
                textView: textViewController.textView,
                matches: &findMatches
            )
            updateMatches(findMatches)
        }

        // Update the emphases
        addMatchEmphases(flashCurrent: true)
    }

    private func replaceMatch(index: Int, target: FindPanelTarget, textView: TextView, matches: inout [NSRange]) {
        let range = matches[index]
        // Set cursor positions to the match range
        textView.replaceCharacters(in: range, with: replaceText)

        // Adjust the length of the replacement
        let lengthDiff = replaceText.utf16.count - range.length

        // Update all match ranges after the current match
        for idx in matches.dropFirst(index + 1).indices {
            matches[idx].location -= lengthDiff
        }
    }
}
