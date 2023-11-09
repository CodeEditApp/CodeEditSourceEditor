//
//  TextView+Select.swift
//  
//
//  Created by Khan Winter on 10/20/23.
//

import AppKit
import TextStory

extension TextView {
    override public func selectAll(_ sender: Any?) {
        selectionManager.setSelectedRange(documentRange)
        unmarkTextIfNeeded()
        needsDisplay = true
    }

    override public func selectLine(_ sender: Any?) {
        let newSelections = selectionManager.textSelections.compactMap { textSelection -> NSRange? in
            guard let linePosition = layoutManager.textLineForOffset(textSelection.range.location) else {
                return nil
            }
            return linePosition.range
        }
        selectionManager.setSelectedRanges(newSelections)
        unmarkTextIfNeeded()
        needsDisplay = true
    }

    override public func selectWord(_ sender: Any?) {
        let newSelections = selectionManager.textSelections.compactMap { (textSelection) -> NSRange? in
            guard textSelection.range.isEmpty,
                  let char = textStorage.substring(
                    from: NSRange(location: textSelection.range.location, length: 1)
                  )?.first else {
                return nil
            }
            let charSet = CharacterSet(charactersIn: String(char))
            let characterSet: CharacterSet
            if CharacterSet.alphanumerics.isSuperset(of: charSet) {
                characterSet = .alphanumerics
            } else if CharacterSet.whitespaces.isSuperset(of: charSet) {
                characterSet = .whitespaces
            } else if CharacterSet.newlines.isSuperset(of: charSet) {
                characterSet = .newlines
            } else if CharacterSet.punctuationCharacters.isSuperset(of: charSet) {
                characterSet = .punctuationCharacters
            } else {
                return nil
            }
            guard let start = textStorage
                .findPrecedingOccurrenceOfCharacter(in: characterSet.inverted, from: textSelection.range.location),
                  let end = textStorage
                .findNextOccurrenceOfCharacter(in: characterSet.inverted, from: textSelection.range.max) else {
                return nil
            }
            return NSRange(
                location: start,
                length: end - start
            )
        }
        selectionManager.setSelectedRanges(newSelections)
        unmarkTextIfNeeded()
        needsDisplay = true
    }
}
