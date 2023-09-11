//
//  File.swift
//  
//
//  Created by Khan Winter on 9/10/23.
//

import Foundation

extension TextView {
    override public func moveUp(_ sender: Any?) {
        moveSelections(direction: .up, destination: .character)
    }

    override public func moveUpAndModifySelection(_ sender: Any?) {
        moveSelections(direction: .up, destination: .character, modifySelection: true)
    }

    override public func moveDown(_ sender: Any?) {
        moveSelections(direction: .down, destination: .character)
    }

    override public func moveDownAndModifySelection(_ sender: Any?) {
        moveSelections(direction: .down, destination: .character, modifySelection: true)
    }

    override public func moveLeft(_ sender: Any?) {
        selectionManager.textSelections.forEach { selection in
            if selection.range.isEmpty {
                moveSelection(selection: selection, direction: .backward, destination: .character)
            } else {
                selection.range.location = selection.range.max
                selection.range.length = 0
            }
        }
        selectionManager.updateSelectionViews()
        setNeedsDisplay()
    }

    override public func moveLeftAndModifySelection(_ sender: Any?) {
        moveSelections(direction: .backward, destination: .character, modifySelection: true)
    }

    override public func moveRight(_ sender: Any?) {
        selectionManager.textSelections.forEach { selection in
            if selection.range.isEmpty {
                moveSelection(selection: selection, direction: .forward, destination: .character)
            } else {
                selection.range.length = 0
            }
        }
        selectionManager.updateSelectionViews()
        setNeedsDisplay()
    }

    override public func moveRightAndModifySelection(_ sender: Any?) {
        moveSelections(direction: .forward, destination: .character, modifySelection: true)
    }

    override public func moveWordLeft(_ sender: Any?) {
        moveSelections(direction: .backward, destination: .word)
    }

    override public func moveWordLeftAndModifySelection(_ sender: Any?) {
        moveSelections(direction: .backward, destination: .word, modifySelection: true)
    }

    override public func moveWordRight(_ sender: Any?) {
        moveSelections(direction: .forward, destination: .word)
    }

    override public func moveWordRightAndModifySelection(_ sender: Any?) {
        moveSelections(direction: .forward, destination: .word, modifySelection: true)
    }

    override public func moveToLeftEndOfLine(_ sender: Any?) {
        moveSelections(direction: .backward, destination: .line)
    }

    override public func moveToLeftEndOfLineAndModifySelection(_ sender: Any?) {
        moveSelections(direction: .backward, destination: .line, modifySelection: true)
    }

    override public func moveToRightEndOfLine(_ sender: Any?) {
        moveSelections(direction: .forward, destination: .line)
    }

    override public func moveToRightEndOfLineAndModifySelection(_ sender: Any?) {
        moveSelections(direction: .forward, destination: .line, modifySelection: true)
    }

    fileprivate func moveSelections(
        direction: TextSelectionManager.Direction,
        destination: TextSelectionManager.Destination,
        modifySelection: Bool = false
    ) {
        selectionManager.textSelections.forEach {
            moveSelection(
                selection: $0,
                direction: direction,
                destination: destination,
                modifySelection: modifySelection
            )
        }
        selectionManager.updateSelectionViews()
        setNeedsDisplay()
    }

    fileprivate func moveSelection(
        selection: TextSelectionManager.TextSelection,
        direction: TextSelectionManager.Direction,
        destination: TextSelectionManager.Destination,
        modifySelection: Bool = false
    ) {
        let range = selectionManager.rangeOfSelection(
            from: direction == .forward ? selection.range.max : selection.range.location,
            direction: direction,
            destination: destination
        )
        if modifySelection {
            selection.range.formUnion(range)
        } else {
            switch direction {
            case .up, .down, .backward:
                selection.range = NSRange(location: range.location, length: 0)
            case .forward:
                selection.range = NSRange(location: range.max, length: 0)
            }
        }
    }
}
