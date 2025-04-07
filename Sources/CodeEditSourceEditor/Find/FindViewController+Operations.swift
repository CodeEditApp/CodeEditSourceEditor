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

        let findOptions: NSRegularExpression.Options = smartCase(str: findText) ? [] : [.caseInsensitive]
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

    private func addEmphases() {
        guard let target = target,
              let emphasisManager = target.emphasisManager else { return }

        // Clear existing emphases
        emphasisManager.removeEmphases(for: "find")

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
        emphasisManager.addEmphases(emphases, for: "find")
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

    // Returns true if string contains uppercase letter
    // used for: ignores letter case if the find text is all lowercase
    private func smartCase(str: String) -> Bool {
        return str.range(of: "[A-Z]", options: .regularExpression) != nil
    }
}
