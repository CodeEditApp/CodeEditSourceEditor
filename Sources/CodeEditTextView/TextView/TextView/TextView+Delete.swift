//
//  TextView+Delete.swift
//  
//
//  Created by Khan Winter on 8/24/23.
//

import AppKit

extension TextView {
    open override func deleteBackward(_ sender: Any?) {
        delete(direction: .backward, destination: .character)
    }

    open override func deleteWordBackward(_ sender: Any?) {
        delete(direction: .backward, destination: .word)
    }

    open override func deleteToBeginningOfLine(_ sender: Any?) {
        delete(direction: .backward, destination: .line)
    }

    private func delete(direction: TextSelectionManager.Direction, destination: TextSelectionManager.Destination) {
        print(#function, direction, destination)
        /// Extend each selection by a distance specified by `destination`, then update both storage and the selection.
        for textSelection in selectionManager.textSelections {
            let extendedRange = selectionManager.rangeOfSelection(
                from: textSelection.range.location,
                direction: direction,
                destination: destination
            )
            textSelection.range.formUnion(extendedRange)
        }

        replaceCharacters(in: selectionManager.textSelections.map(\.range), with: "")

        var delta: Int = 0
        for textSelection in selectionManager.textSelections {
            textSelection.range.location -= delta
            delta += textSelection.range.length
            textSelection.range.length = 0
        }

        selectionManager.updateSelectionViews()
    }
}
