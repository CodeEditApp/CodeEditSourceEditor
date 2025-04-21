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

            let sortedMatches = findMatches.sorted(by: { $0.location > $1.location })
            for idx in sortedMatches.indices {
                replaceMatch(index: idx, target: target, textView: textViewController.textView)
            }
            textViewController.textView.undoManager?.endUndoGrouping()

            if let lastMatch = sortedMatches.first {
                target.setCursorPositions(
                    [CursorPosition(range: NSRange(location: lastMatch.location, length: 0))],
                    scrollToVisible: true
                )
            }

            updateMatches([])
        } else {
            replaceMatch(index: currentFindMatchIndex, target: target, textView: textViewController.textView)
        }

        // Update the emphases
        addMatchEmphases(flashCurrent: true)
    }

    private func replaceMatch(index: Int, target: FindPanelTarget, textView: TextView) {
        let range = findMatches[index]
        // Set cursor positions to the match range
        textView.replaceCharacters(in: [range], with: replaceText)

        // Adjust the length of the replacement
        let lengthDiff = replaceText.utf16.count - range.length

        // Update all match ranges after the current match
        for idx in findMatches.dropFirst(index).indices {
            findMatches[idx].location -= lengthDiff
        }
    }
}
