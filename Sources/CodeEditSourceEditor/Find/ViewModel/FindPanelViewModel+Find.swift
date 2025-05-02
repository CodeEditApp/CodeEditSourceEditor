//
//  FindPanelViewModel+Find.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 4/18/25.
//

import Foundation

extension FindPanelViewModel {
    // MARK: - Find

    /// Performs a find operation on the find target and updates both the ``findMatches`` array and the emphasis
    /// manager's emphases.
    func find() {
        // Don't find if target or emphasisManager isn't ready or the query is empty
        guard let target = target, isFocused, !findText.isEmpty else {
            self.findMatches = []
            return
        }

        // Set case sensitivity based on matchCase property
        let findOptions: NSRegularExpression.Options = matchCase ? [] : [.caseInsensitive]
        let escapedQuery = NSRegularExpression.escapedPattern(for: findText)

        guard let regex = try? NSRegularExpression(pattern: escapedQuery, options: findOptions) else {
            self.findMatches = []
            self.currentFindMatchIndex = 0
            return
        }

        let text = target.text
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))

        self.findMatches = matches.map(\.range)

        // Find the nearest match to the current cursor position
        currentFindMatchIndex = getNearestEmphasisIndex(matchRanges: findMatches) ?? 0
        addMatchEmphases(flashCurrent: false)
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

}
