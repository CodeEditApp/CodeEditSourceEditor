//
//  SearchManager.swift
//  CodeEditSourceEditor
//
//  Created by Tommy Ludwig on 03.02.25.
//

import AppKit
import CodeEditTextView

extension TextViewController {
    @objc func searchFieldUpdated(_ notification: Notification) {
        if let textField = notification.object as? NSTextField {
            searchFile(query: textField.stringValue)
        }
    }

    @objc func onSubmit() {
        if let highlightedRange = textView.emphasizeAPI?.emphasizedRanges[textView.emphasizeAPI?.emphasizedRangeIndex ?? 0] {
            setCursorPositions([CursorPosition(range: highlightedRange.range)])
            updateCursorPosition()
        }
    }

    @objc func prevButtonClicked() {
        textView?.emphasizeAPI?.highlightPrevious()
        if let currentRange = textView.emphasizeAPI?.emphasizedRanges[(textView.emphasizeAPI?.emphasizedRangeIndex) ?? 0].range {
            textView.scrollToRange(currentRange)
        }
    }

    @objc func nextButtonClicked() {
        textView?.emphasizeAPI?.highlightNext()
        if let currentRange = textView.emphasizeAPI?.emphasizedRanges[(textView.emphasizeAPI?.emphasizedRangeIndex) ?? 0].range {
            textView.scrollToRange(currentRange)
            self.gutterView.needsDisplay = true
        }
    }

    func searchFile(query: String) {
        let searchOptions: NSRegularExpression.Options = smartCase(str: query) ? [] : [.caseInsensitive]
        let escapedQuery = NSRegularExpression.escapedPattern(for: query)

        guard let regex = try? NSRegularExpression(pattern: escapedQuery, options: searchOptions) else {
            textView?.emphasizeAPI?.removeEmphasizeLayers()
            return
        }

        let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        guard !matches.isEmpty else {
            textView?.emphasizeAPI?.removeEmphasizeLayers()
            return
        }

        let searchResults = matches.map { $0.range }
        let bestHighlightIndex = getNearestHighlightIndex(ranges: searchResults) ?? 0
        print(searchResults.count)
        textView?.emphasizeAPI?.emphasizeRanges(ranges: searchResults, activeIndex: bestHighlightIndex)
        cursorPositions = [CursorPosition(range: searchResults[bestHighlightIndex])]
    }

    private func getNearestHighlightIndex(ranges: [NSRange]) -> Int? {
        // order the array as follows
        // Found: 1 -> 2 -> 3 -> 4
        // Cursor:       |
        // Result: 3 -> 4 -> 1 -> 2
        guard let cursorPosition = cursorPositions.first else { return nil }
        let start = cursorPosition.range.location

        var left = 0
        var right = ranges.count - 1
        var bestIndex = -1
        var bestDiff = Int.max  // Stores the closest difference

        while left <= right {
            let mid = left + (right - left) / 2
            let midStart = ranges[mid].location
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

    // Only re-serach the part of the file that changed upwards
    private func reSearch() { }

    // Returns true if string contains uppercase letter
    // used for: ignores letter case if the search query is all lowercase
    private func smartCase(str: String) -> Bool {
        return str.range(of: "[A-Z]", options: .regularExpression) != nil
    }
}
