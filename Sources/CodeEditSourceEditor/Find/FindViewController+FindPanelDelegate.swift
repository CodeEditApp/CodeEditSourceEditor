//
//  FindViewController+Delegate.swift
//  CodeEditSourceEditor
//
//  Created by Austin Condiff on 4/3/25.
//

import AppKit
import CodeEditTextView

extension FindViewController: FindPanelDelegate {
    func findPanelOnSubmit() {
        findPanelNextButtonClicked()
    }

    func findPanelOnDismiss() {
        if isShowingFindPanel {
            hideFindPanel()
            // Ensure text view becomes first responder after hiding
            if let textViewController = target as? TextViewController {
                DispatchQueue.main.async {
                    _ = textViewController.textView.window?.makeFirstResponder(textViewController.textView)
                }
            }
        }
    }

    func findPanelDidUpdate(_ text: String) {
        // Check if this update was triggered by a return key without shift
        if let currentEvent = NSApp.currentEvent,
           currentEvent.type == .keyDown,
           currentEvent.keyCode == 36, // Return key
           !currentEvent.modifierFlags.contains(.shift) {
            return // Skip find for regular return key
        }

        // Only perform find if we're focusing the text view
        if let textViewController = target as? TextViewController,
           textViewController.textView.window?.firstResponder === textViewController.textView {
            // If the text view has focus, just clear visual emphases but keep matches in memory
            target?.emphasisManager?.removeEmphases(for: "find")
            // Re-add the current active emphasis without visual emphasis
            if let emphases = target?.emphasisManager?.getEmphases(for: "find"),
               let activeEmphasis = emphases.first(where: { !$0.inactive }) {
                target?.emphasisManager?.addEmphasis(
                    Emphasis(
                        range: activeEmphasis.range,
                        style: .standard,
                        flash: false,
                        inactive: false,
                        selectInDocument: true
                    ),
                    for: "find"
                )
            }
            return
        }

        // Clear existing emphases before performing new find
        target?.emphasisManager?.removeEmphases(for: "find")
        find(text: text)
    }

    func findPanelPrevButtonClicked() {
        guard let textViewController = target as? TextViewController,
              let emphasisManager = target?.emphasisManager else { return }

        // Check if there are any matches
        if findMatches.isEmpty {
            return
        }

        // Update to previous match
        let oldIndex = currentFindMatchIndex
        currentFindMatchIndex = (currentFindMatchIndex - 1 + findMatches.count) % findMatches.count

        // Show bezel notification if we cycled from first to last match
        if oldIndex == 0 && currentFindMatchIndex == findMatches.count - 1 {
            BezelNotification.show(
                symbolName: "arrow.trianglehead.bottomleft.capsulepath.clockwise",
                over: textViewController.textView
            )
        }

        // If the text view has focus, show a flash animation for the current match
        if textViewController.textView.window?.firstResponder === textViewController.textView {
            let newActiveRange = findMatches[currentFindMatchIndex]

            // Clear existing emphases before adding the flash
            emphasisManager.removeEmphases(for: "find")

            emphasisManager.addEmphasis(
                Emphasis(
                    range: newActiveRange,
                    style: .standard,
                    flash: true,
                    inactive: false,
                    selectInDocument: true
                ),
                for: "find"
            )

            return
        }

        // Create updated emphases with new active state
        let updatedEmphases = findMatches.enumerated().map { index, range in
            Emphasis(
                range: range,
                style: .standard,
                flash: false,
                inactive: index != currentFindMatchIndex,
                selectInDocument: index == currentFindMatchIndex
            )
        }

        // Replace all emphases to update state
        emphasisManager.replaceEmphases(updatedEmphases, for: "find")
    }

    func findPanelNextButtonClicked() {
        guard let textViewController = target as? TextViewController,
              let emphasisManager = target?.emphasisManager else { return }

        // Check if there are any matches
        if findMatches.isEmpty {
            // Show "no matches" bezel notification and play beep
            NSSound.beep()
            BezelNotification.show(
                symbolName: "arrow.down.to.line",
                over: textViewController.textView
            )
            return
        }

        // Update to next match
        let oldIndex = currentFindMatchIndex
        currentFindMatchIndex = (currentFindMatchIndex + 1) % findMatches.count

        // Show bezel notification if we cycled from last to first match
        if oldIndex == findMatches.count - 1 && currentFindMatchIndex == 0 {
            BezelNotification.show(
                symbolName: "arrow.triangle.capsulepath",
                over: textViewController.textView
            )
        }

        // If the text view has focus, show a flash animation for the current match
        if textViewController.textView.window?.firstResponder === textViewController.textView {
            let newActiveRange = findMatches[currentFindMatchIndex]

            // Clear existing emphases before adding the flash
            emphasisManager.removeEmphases(for: "find")

            emphasisManager.addEmphasis(
                Emphasis(
                    range: newActiveRange,
                    style: .standard,
                    flash: true,
                    inactive: false,
                    selectInDocument: true
                ),
                for: "find"
            )

            return
        }

        // Create updated emphases with new active state
        let updatedEmphases = findMatches.enumerated().map { index, range in
            Emphasis(
                range: range,
                style: .standard,
                flash: false,
                inactive: index != currentFindMatchIndex,
                selectInDocument: index == currentFindMatchIndex
            )
        }

        // Replace all emphases to update state
        emphasisManager.replaceEmphases(updatedEmphases, for: "find")
    }

    func findPanelUpdateMatchCount(_ count: Int) {
        findPanel.updateMatchCount(count)
    }

    func findPanelClearEmphasis() {
        target?.emphasisManager?.removeEmphases(for: "find")
    }
}
