//
//  TextView+TextFormation.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 10/14/23.
//

import Foundation
import CodeEditTextView
import TextStory
import TextFormation

extension TextView: TextInterface {
    public var selectedRange: NSRange {
        get {
            return selectionManager
                .textSelections
                .sorted(by: { $0.range.lowerBound < $1.range.lowerBound })
                .first?
                .range ?? .zero
        }
        set {
            selectionManager.setSelectedRange(newValue)
        }
    }

    public var length: Int {
        textStorage.length
    }

    public func substring(from range: NSRange) -> String? {
        return textStorage.substring(from: range)
    }

    /// Applies the mutation to the text view.
    /// - Parameter mutation: The mutation to apply.
    public func applyMutation(_ mutation: TextMutation) {
        layoutManager.willReplaceCharactersInRange(range: mutation.range, with: mutation.string)
        selectionManager.didReplaceCharacters(
            in: mutation.range,
            replacementLength: (mutation.string as NSString).length
        )
        textStorage.replaceCharacters(in: mutation.range, with: mutation.string)
    }
}
