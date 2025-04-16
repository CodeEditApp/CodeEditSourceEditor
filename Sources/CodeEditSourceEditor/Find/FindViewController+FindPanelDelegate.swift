//
//  FindViewController+Delegate.swift
//  CodeEditSourceEditor
//
//  Created by Austin Condiff on 4/3/25.
//

import AppKit
import CodeEditTextView

extension FindViewController: FindPanelDelegate {
    var findPanelMode: FindPanelMode { mode }
    var findPanelWrapAround: Bool { wrapAround }
    var findPanelMatchCase: Bool { matchCase }

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
            target?.emphasisManager?.removeEmphases(for: EmphasisGroup.find)
            // Re-add the current active emphasis without visual emphasis
            if let emphases = target?.emphasisManager?.getEmphases(for: EmphasisGroup.find),
               let activeEmphasis = emphases.first(where: { !$0.inactive }) {
                target?.emphasisManager?.addEmphasis(
                    Emphasis(
                        range: activeEmphasis.range,
                        style: .standard,
                        flash: false,
                        inactive: false,
                        selectInDocument: true
                    ),
                    for: EmphasisGroup.find
                )
            }
            return
        }

        // Clear existing emphases before performing new find
        target?.emphasisManager?.removeEmphases(for: EmphasisGroup.find)
        find(text: text)
    }

    func findPanelDidUpdateMode(_ mode: FindPanelMode) {
        self.mode = mode
        if isShowingFindPanel {
            target?.findPanelModeDidChange(to: mode, panelHeight: panelHeight)
        }
    }

    func findPanelDidUpdateWrapAround(_ wrapAround: Bool) {
        self.wrapAround = wrapAround
    }

    func findPanelDidUpdateMatchCase(_ matchCase: Bool) {
        self.matchCase = matchCase
        if !findText.isEmpty {
            performFind()
            addEmphases()
        }
    }

    func findPanelDidUpdateReplaceText(_ text: String) {
        self.replaceText = text
    }

    private func flashCurrentMatch(emphasisManager: EmphasisManager, textViewController: TextViewController) {
        let newActiveRange = findMatches[currentFindMatchIndex]
        emphasisManager.removeEmphases(for: EmphasisGroup.find)
        emphasisManager.addEmphasis(
            Emphasis(
                range: newActiveRange,
                style: .standard,
                flash: true,
                inactive: false,
                selectInDocument: true
            ),
            for: EmphasisGroup.find
        )
    }

    func findPanelPrevButtonClicked() {
        guard let textViewController = target as? TextViewController,
              let emphasisManager = target?.emphasisManager else { return }

        // Check if there are any matches
        if findMatches.isEmpty {
            NSSound.beep()
            BezelNotification.show(
                symbolName: "arrow.up.to.line",
                over: textViewController.textView
            )
            return
        }

        // Check if we're at the first match and wrapAround is false
        if !wrapAround && currentFindMatchIndex == 0 {
            NSSound.beep()
            BezelNotification.show(
                symbolName: "arrow.up.to.line",
                over: textViewController.textView
            )
            if textViewController.textView.window?.firstResponder === textViewController.textView {
                flashCurrentMatch(emphasisManager: emphasisManager, textViewController: textViewController)
                return
            }
            updateEmphasesForCurrentMatch(emphasisManager: emphasisManager)
            return
        }

        // Update to previous match
        currentFindMatchIndex = (currentFindMatchIndex - 1 + findMatches.count) % findMatches.count

        // If the text view has focus, show a flash animation for the current match
        if textViewController.textView.window?.firstResponder === textViewController.textView {
            flashCurrentMatch(emphasisManager: emphasisManager, textViewController: textViewController)
            return
        }

        updateEmphasesForCurrentMatch(emphasisManager: emphasisManager)
    }

    private func updateEmphasesForCurrentMatch(emphasisManager: EmphasisManager, flash: Bool = false) {
        // Create updated emphases with current match emphasized
        let updatedEmphases = findMatches.enumerated().map { index, range in
            Emphasis(
                range: range,
                style: .standard,
                flash: flash,
                inactive: index != currentFindMatchIndex,
                selectInDocument: index == currentFindMatchIndex
            )
        }

        // Replace all emphases to update state
        emphasisManager.replaceEmphases(updatedEmphases, for: EmphasisGroup.find)
    }

    func findPanelNextButtonClicked() {
        guard let textViewController = target as? TextViewController,
              let emphasisManager = target?.emphasisManager else { return }

        // Check if there are any matches
        if findMatches.isEmpty {
            NSSound.beep()
            BezelNotification.show(
                symbolName: "arrow.down.to.line",
                over: textViewController.textView
            )
            return
        }

        // Check if we're at the last match and wrapAround is false
        if !wrapAround && currentFindMatchIndex == findMatches.count - 1 {
            NSSound.beep()
            BezelNotification.show(
                symbolName: "arrow.down.to.line",
                over: textViewController.textView
            )
            if textViewController.textView.window?.firstResponder === textViewController.textView {
                flashCurrentMatch(emphasisManager: emphasisManager, textViewController: textViewController)
                return
            }
            updateEmphasesForCurrentMatch(emphasisManager: emphasisManager)
            return
        }

        // Update to next match
        currentFindMatchIndex = (currentFindMatchIndex + 1) % findMatches.count

        // If the text view has focus, show a flash animation for the current match
        if textViewController.textView.window?.firstResponder === textViewController.textView {
            flashCurrentMatch(emphasisManager: emphasisManager, textViewController: textViewController)
            return
        }

        updateEmphasesForCurrentMatch(emphasisManager: emphasisManager)
    }

    func findPanelReplaceButtonClicked() {
        guard !findMatches.isEmpty else { return }
        replaceCurrentMatch()
    }

    func findPanelUpdateMatchCount(_ count: Int) {
        findPanel.updateMatchCount(count)
    }

    func findPanelClearEmphasis() {
        target?.emphasisManager?.removeEmphases(for: EmphasisGroup.find)
    }
}
