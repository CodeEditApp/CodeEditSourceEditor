//
//  STTextView+AutoComplete.swift
//  
//
//  Created by Lukas Pistrol on 25.05.22.
//

import AppKit
import STTextView

extension STTextView {
    private var autoPairs: [String: String] {
        [
            "(": ")",
            "{": "}",
            "[": "]"
            // not working yet
            //            "\"": "\"",
            //            "\'": "\'"
        ]
    }

    func autocompleteSymbols(_ symbol: String) {
        guard let end = autoPairs[symbol],
              nextSymbol() != end else { return }
        insertText(end, replacementRange: selectedRange())
        moveBackward(self)
    }

    private func nextSymbol() -> String {
        let start = selectedRange().location
        let nextRange = NSRange(location: start, length: 1)
        let nextSymbol = string[nextRange]
        return String(nextSymbol)
    }
}
