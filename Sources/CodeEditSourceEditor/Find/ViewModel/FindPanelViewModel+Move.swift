//
//  FindPanelViewModel+Move.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 4/18/25.
//

import AppKit

extension FindPanelViewModel {
    func moveToNextMatch() {
        moveMatch(forwards: true)
    }

    func moveToPreviousMatch() {
        moveMatch(forwards: false)
    }

    func moveMatch(forwards: Bool, keepExistingSelections: Bool = false) {
        guard let target = target else { return }

        guard !findMatches.isEmpty else {
            showWrapNotification(forwards: forwards, error: true, targetView: target.findPanelTargetView)
            return
        }

        // From here on out we want to emphasize the result no matter what
        defer {
            if isTargetFirstResponder {
                flashCurrentMatch(allowSelection: !keepExistingSelections)
            } else {
                addMatchEmphases(flashCurrent: isTargetFirstResponder, allowSelection: !keepExistingSelections)
            }
        }

        guard let currentFindMatchIndex else {
            self.currentFindMatchIndex = 0
            return
        }

        // Only increment/decrement the index if we're not keeping existing selections
        if !keepExistingSelections {
            let isAtLimit = forwards ? currentFindMatchIndex == findMatches.count - 1 : currentFindMatchIndex == 0

            guard !isAtLimit || wrapAround else {
                showWrapNotification(forwards: forwards, error: true, targetView: target.findPanelTargetView)
                return
            }

            self.currentFindMatchIndex = if forwards {
                (currentFindMatchIndex + 1) % findMatches.count
            } else {
                (currentFindMatchIndex - 1 + (findMatches.count)) % findMatches.count
            }

            if isAtLimit {
                showWrapNotification(forwards: forwards, error: false, targetView: target.findPanelTargetView)
            }
        } else {
            // When keeping existing selections, we still need to respect wrapAround
            let isAtLimit = forwards ? currentFindMatchIndex == findMatches.count - 1 : currentFindMatchIndex == 0
            
            if isAtLimit && !wrapAround {
                showWrapNotification(forwards: forwards, error: true, targetView: target.findPanelTargetView)
                return
            }
            
            if isAtLimit && wrapAround {
                showWrapNotification(forwards: forwards, error: false, targetView: target.findPanelTargetView)
            }
        }

        // If keeping existing selections, add the new match to them
        if keepExistingSelections {
            let newRange = findMatches[self.currentFindMatchIndex!]
            var newRanges = target.textView.selectionManager.textSelections.map { $0.range }
            
            // Add the new range if it's not already selected
            if !newRanges.contains(where: { $0.location == newRange.location && $0.length == newRange.length }) {
                newRanges.append(newRange)
            }
            
            // Set all selections at once
            target.textView.selectionManager.setSelectedRanges(newRanges)
            
            // Update cursor positions to match
            var newPositions = target.cursorPositions
            newPositions.append(CursorPosition(range: newRange))
            target.setCursorPositions(newPositions, scrollToVisible: true)
        }
    }

    /// Shows a bezel notification for wrap around or end of search
    /// - Parameters:
    ///   - forwards: Whether we're moving forwards or backwards
    ///   - error: Whether this is an error (no more matches) or a wrap around
    ///   - targetView: The view to show the notification over
    func showWrapNotification(forwards: Bool, error: Bool, targetView: NSView) {
        if error {
            NSSound.beep()
        }
        BezelNotification.show(
            symbolName: error ?
            forwards ? "arrow.down.to.line" : "arrow.up.to.line"
            : forwards
                ? "arrow.trianglehead.topright.capsulepath.clockwise"
                : "arrow.trianglehead.bottomleft.capsulepath.clockwise",
            over: targetView
        )
    }
}
