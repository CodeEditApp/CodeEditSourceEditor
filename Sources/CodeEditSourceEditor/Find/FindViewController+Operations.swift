//
//  FindViewController+Operations.swift
//  CodeEditSourceEditor
//
//  Created by Austin Condiff on 4/3/25.
//

import AppKit
import CodeEditTextView

extension FindViewController {
    func find(text: String) {
        findText = text
        performFind()
        addEmphases()
    }

    func performFind() {
        // Don't find if target or emphasisManager isn't ready
        guard let target = target else {
            findPanel.findDelegate?.findPanelUpdateMatchCount(0)
            findMatches = []
            currentFindMatchIndex = 0
            return
        }

        // Clear emphases and return if query is empty
        if findText.isEmpty {
            findPanel.findDelegate?.findPanelUpdateMatchCount(0)
            findMatches = []
            currentFindMatchIndex = 0
            return
        }

        // Set case sensitivity based on matchCase property
        let findOptions: NSRegularExpression.Options = matchCase ? [] : [.caseInsensitive]
        let escapedQuery = NSRegularExpression.escapedPattern(for: findText)

        guard let regex = try? NSRegularExpression(pattern: escapedQuery, options: findOptions) else {
            findPanel.findDelegate?.findPanelUpdateMatchCount(0)
            findMatches = []
            currentFindMatchIndex = 0
            return
        }

        let text = target.text
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))

        findMatches = matches.map { $0.range }
        findPanel.findDelegate?.findPanelUpdateMatchCount(findMatches.count)

        // Find the nearest match to the current cursor position
        currentFindMatchIndex = getNearestEmphasisIndex(matchRanges: findMatches) ?? 0
    }

    func replaceCurrentMatch() {
        guard let target = target,
              !findMatches.isEmpty else { return }

        // Get the current match range
        let currentMatchRange = findMatches[currentFindMatchIndex]

        // Set cursor positions to the match range
        target.setCursorPositions([CursorPosition(range: currentMatchRange)])

        // Replace the text using the cursor positions
        if let textViewController = target as? TextViewController {
            textViewController.textView.insertText(replaceText, replacementRange: currentMatchRange)
        }

        // Adjust the length of the replacement
        let lengthDiff = replaceText.utf16.count - currentMatchRange.length

        // Update the current match index
        if findMatches.isEmpty {
            currentFindMatchIndex = 0
            findPanel.findDelegate?.findPanelUpdateMatchCount(0)
        } else {
            // Update all match ranges after the current match
            for index in (currentFindMatchIndex + 1)..<findMatches.count {
                findMatches[index].location += lengthDiff
            }

            // Remove the current match from the array
            findMatches.remove(at: currentFindMatchIndex)

            // Keep the current index in bounds
            currentFindMatchIndex = min(currentFindMatchIndex, findMatches.count - 1)
            findPanel.findDelegate?.findPanelUpdateMatchCount(findMatches.count)
        }

        // Update the emphases
        addEmphases()
    }

    func addEmphases() {
        guard let target = target,
              let emphasisManager = target.emphasisManager else { return }

        // Clear existing emphases
        emphasisManager.removeEmphases(for: EmphasisGroup.find)

        // Create emphasis with the nearest match as active
        let emphases = findMatches.enumerated().map { index, range in
            Emphasis(
                range: range,
                style: .standard,
                flash: false,
                inactive: index != currentFindMatchIndex,
                selectInDocument: index == currentFindMatchIndex
            )
        }

        // Add all emphases
        emphasisManager.addEmphases(emphases, for: EmphasisGroup.find)
    }

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

    // Only re-find the part of the file that changed upwards
    private func reFind() { }
}
