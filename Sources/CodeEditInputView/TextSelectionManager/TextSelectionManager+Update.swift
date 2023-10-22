//
//  TextSelectionManager+Update.swift
//
//
//  Created by Khan Winter on 10/22/23.
//

import Foundation

extension TextSelectionManager {
    internal func willReplaceCharacters(in range: NSRange, replacementLength: Int) {
        let delta = replacementLength == 0 ? -range.length : replacementLength
        for textSelection in self.textSelections {
            if textSelection.range.location > range.max {
                textSelection.range.location = max(0, textSelection.range.location + delta)
                textSelection.range.length = 0
            } else if textSelection.range.intersection(range) != nil || textSelection.range == range {
                if replacementLength > 0 {
                    textSelection.range.location = range.location + replacementLength
                } else {
                    textSelection.range.location = range.location
                }
                textSelection.range.length = 0
            } else {
                textSelection.range.length = 0
            }
        }

        // Clean up duplicate selection ranges
        var allRanges: Set<NSRange> = []
        for (i, selection) in self.textSelections.enumerated().reversed() {
            if allRanges.contains(selection.range) {
                self.textSelections.remove(at: i)
            } else {
                allRanges.insert(selection.range)
            }
        }
    }

    internal func notifyAfterEdit() {
        updateSelectionViews()
        NotificationCenter.default.post(Notification(name: Self.selectionChangedNotification, object: self))
    }
}
