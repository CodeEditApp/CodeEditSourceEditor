//
//  FindPanelViewModel+Find.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 4/18/25.
//

import Foundation
import CodeEditTextView

extension FindPanelViewModel {
    // MARK: - Find

    /// Performs a find operation on the find target and updates both the ``findMatches`` array and the emphasis
    /// manager's emphases.
    func find() {
        // Don't find if target isn't ready or the query is empty
        guard let target = target, !findText.isEmpty else {
            self.findMatches = []
            return
        }

        // Set case sensitivity based on matchCase property
        var findOptions: NSRegularExpression.Options = matchCase ? [] : [.caseInsensitive]

        // Add multiline options for regular expressions
        if findMethod == .regularExpression {
            findOptions.insert(.dotMatchesLineSeparators)
            findOptions.insert(.anchorsMatchLines)
        }

        let pattern: String

        switch findMethod {
        case .contains:
            // Simple substring match, escape special characters
            pattern = NSRegularExpression.escapedPattern(for: findText)

        case .matchesWord:
            // Match whole words only using word boundaries
            pattern = "\\b" + NSRegularExpression.escapedPattern(for: findText) + "\\b"

        case .startsWith:
            // Match at the start of a line or after a word boundary
            pattern = "(?:^|\\b)" + NSRegularExpression.escapedPattern(for: findText)

        case .endsWith:
            // Match at the end of a line or before a word boundary
            pattern = NSRegularExpression.escapedPattern(for: findText) + "(?:$|\\b)"

        case .regularExpression:
            // Use the pattern directly without additional escaping
            pattern = findText
        }

        guard let regex = try? NSRegularExpression(pattern: pattern, options: findOptions) else {
            self.findMatches = []
            self.currentFindMatchIndex = nil
            return
        }

        let text = target.textView.string
        let range = target.textView.documentRange
        let matches = regex.matches(in: text, range: range).filter { !$0.range.isEmpty }

        self.findMatches = matches.map(\.range)

        // Only set currentFindMatchIndex if we're not doing multiple selection
        if !isFocused {
            currentFindMatchIndex = getNearestEmphasisIndex(matchRanges: findMatches)
        }

        // Only add emphasis layers if the find panel is focused
        if isFocused {
            addMatchEmphases(flashCurrent: false)
        }
    }

    // MARK: - Get Nearest Emphasis Index

    private func getNearestEmphasisIndex(matchRanges: [NSRange]) -> Int? {
        // order the array as follows
        // Found: 1 -> 2 -> 3 -> 4
        // Cursor:       |
        // Result: 3 -> 4 -> 1 -> 2
        guard let cursorPosition = target?.cursorPositions.first else { return nil }
        let start = cursorPosition.range.location

        var left = 0
        var right = matchRanges.count - 1
        var bestIndex = -1
        var bestDiff = Int.max  // Stores the closest difference

        while left <= right {
            let mid = left + (right - left) / 2
            let midStart = matchRanges[mid].location
            let diff = abs(midStart - start)

            // If it's an exact match, return immediately
            if diff == 0 {
                return mid
            }

            // If this is the closest so far, update the best index
            if diff < bestDiff {
                bestDiff = diff
                bestIndex = mid
            }

            // Move left or right based on the cursor position
            if midStart < start {
                left = mid + 1
            } else {
                right = mid - 1
            }
        }

        return bestIndex >= 0 ? bestIndex : nil
    }

    // MARK: - Multiple Selection Support

    /// Selects the next occurrence of the current selection while maintaining existing selections
    func selectNextOccurrence() {
        guard let target = target,
              let currentSelection = target.cursorPositions.first?.range else {
            return
        }

        // Set find text to the current selection
        let selectedText = (target.textView.string as NSString).substring(with: currentSelection)

        // Only update findText if it's different from the current selection
        if findText != selectedText {
            findText = selectedText
            // Clear existing matches since we're searching for something new
            findMatches = []
            currentFindMatchIndex = nil
        }

        // Perform find if we haven't already
        if findMatches.isEmpty {
            find()
        }

        // Find the next unselected match
        let selectedRanges = target.cursorPositions.map { $0.range }

        // Find the index of the current selection
        if let currentIndex = findMatches.firstIndex(where: { $0.location == currentSelection.location }) {
            // Find the next unselected match
            var nextIndex = (currentIndex + 1) % findMatches.count
            var wrappedAround = false

            while selectedRanges.contains(where: { $0.location == findMatches[nextIndex].location }) {
                nextIndex = (nextIndex + 1) % findMatches.count
                // If we've gone all the way around, break to avoid infinite loop
                if nextIndex == currentIndex {
                    // If we've wrapped around and still haven't found an unselected match,
                    // show the "no more matches" notification and flash the current match
                    showWrapNotification(forwards: true, error: true, targetView: target.findPanelTargetView)
                    if let currentIndex = currentFindMatchIndex {
                        target.textView.emphasisManager?.addEmphases([
                            Emphasis(
                                range: findMatches[currentIndex],
                                style: .standard,
                                flash: true,
                                inactive: false,
                                selectInDocument: false
                            )
                        ], for: EmphasisGroup.find)
                    }
                    return
                }
                // If we've wrapped around once, set the flag
                if nextIndex == 0 {
                    wrappedAround = true
                }
            }

            // If we wrapped around and wrapAround is false, show the "no more matches" notification
            if wrappedAround && !wrapAround {
                showWrapNotification(forwards: true, error: true, targetView: target.findPanelTargetView)
                if let currentIndex = currentFindMatchIndex {
                    target.textView.emphasisManager?.addEmphases([
                        Emphasis(
                            range: findMatches[currentIndex],
                            style: .standard,
                            flash: true,
                            inactive: false,
                            selectInDocument: false
                        )
                    ], for: EmphasisGroup.find)
                }
                return
            }

            // If we wrapped around and wrapAround is true, show the wrap notification
            if wrappedAround {
                showWrapNotification(forwards: true, error: false, targetView: target.findPanelTargetView)
            }

            currentFindMatchIndex = nextIndex
        } else {
            currentFindMatchIndex = nil
        }

        // Use the existing moveMatch function with keepExistingSelections enabled
        moveMatch(forwards: true, keepExistingSelections: true)
    }

    /// Selects the previous occurrence of the current selection while maintaining existing selections
    func selectPreviousOccurrence() {
        guard let target = target,
              let currentSelection = target.cursorPositions.first?.range else {
            return
        }

        // Set find text to the current selection
        let selectedText = (target.textView.string as NSString).substring(with: currentSelection)

        // Only update findText if it's different from the current selection
        if findText != selectedText {
            findText = selectedText
            // Clear existing matches since we're searching for something new
            findMatches = []
            currentFindMatchIndex = nil
        }

        // Perform find if we haven't already
        if findMatches.isEmpty {
            find()
        }

        // Find the previous unselected match
        let selectedRanges = target.cursorPositions.map { $0.range }

        // Find the index of the current selection
        if let currentIndex = findMatches.firstIndex(where: { $0.location == currentSelection.location }) {
            // Find the previous unselected match
            var prevIndex = (currentIndex - 1 + findMatches.count) % findMatches.count
            var wrappedAround = false

            while selectedRanges.contains(where: { $0.location == findMatches[prevIndex].location }) {
                prevIndex = (prevIndex - 1 + findMatches.count) % findMatches.count
                // If we've gone all the way around, break to avoid infinite loop
                if prevIndex == currentIndex {
                    // If we've wrapped around and still haven't found an unselected match,
                    // show the "no more matches" notification and flash the current match
                    showWrapNotification(forwards: false, error: true, targetView: target.findPanelTargetView)
                    if let currentIndex = currentFindMatchIndex {
                        target.textView.emphasisManager?.addEmphases([
                            Emphasis(
                                range: findMatches[currentIndex],
                                style: .standard,
                                flash: true,
                                inactive: false,
                                selectInDocument: false
                            )
                        ], for: EmphasisGroup.find)
                    }
                    return
                }
                // If we've wrapped around once, set the flag
                if prevIndex == findMatches.count - 1 {
                    wrappedAround = true
                }
            }

            // If we wrapped around and wrapAround is false, show the "no more matches" notification
            if wrappedAround && !wrapAround {
                showWrapNotification(forwards: false, error: true, targetView: target.findPanelTargetView)
                if let currentIndex = currentFindMatchIndex {
                    target.textView.emphasisManager?.addEmphases([
                        Emphasis(
                            range: findMatches[currentIndex],
                            style: .standard,
                            flash: true,
                            inactive: false,
                            selectInDocument: false
                        )
                    ], for: EmphasisGroup.find)
                }
                return
            }

            // If we wrapped around and wrapAround is true, show the wrap notification
            if wrappedAround {
                showWrapNotification(forwards: false, error: false, targetView: target.findPanelTargetView)
            }

            currentFindMatchIndex = prevIndex
        } else {
            currentFindMatchIndex = nil
        }

        // Use the existing moveMatch function with keepExistingSelections enabled
        moveMatch(forwards: false, keepExistingSelections: true)
    }

}
