//
//  TextView+Select.swift
//  
//
//  Created by Khan Winter on 10/20/23.
//

import AppKit

extension TextView {
    override public func selectAll(_ sender: Any?) {
        selectionManager.setSelectedRange(documentRange)
        needsDisplay = true
    }

    override public func selectLine(_ sender: Any?) {
        let newSelections = selectionManager.textSelections.map {
            textStorage.lineRange(containing: $0.range.location)
        }
        selectionManager.setSelectedRanges(newSelections)
        needsDisplay = true
    }

    override public func selectWord(_ sender: Any?) {
        // TODO: Select word
        needsDisplay = true
    }
}
