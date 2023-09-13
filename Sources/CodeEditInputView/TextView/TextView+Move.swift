//
//  File.swift
//  
//
//  Created by Khan Winter on 9/10/23.
//

import Foundation

extension TextView {
    // TODO: Move up/down character need to remember the xPos they started at.
    // Comment for TODO. When moving up/down users expect to move across lines of different lengths while keeping their
    // cursor as close as possible to the original x position. This needs to be implemented.

    /// Moves the cursors up one character.
    override public func moveUp(_ sender: Any?) {
        moveSelections(direction: .up, destination: .character)
    }

    /// Moves the cursors up one character extending the current selection.
    override public func moveUpAndModifySelection(_ sender: Any?) {
        moveSelections(direction: .up, destination: .character, modifySelection: true)
    }

    /// Moves the cursors down one character.
    override public func moveDown(_ sender: Any?) {
        moveSelections(direction: .down, destination: .character)
    }

    /// Moves the cursors down one character extending the current selection.
    override public func moveDownAndModifySelection(_ sender: Any?) {
        moveSelections(direction: .down, destination: .character, modifySelection: true)
    }

    /// Moves the cursors left one character.
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
        scrollSelectionToVisible()
        setNeedsDisplay()
    }

    /// Moves the cursors left one character extending the current selection.
    override public func moveLeftAndModifySelection(_ sender: Any?) {
        moveSelections(direction: .backward, destination: .character, modifySelection: true)
    }

    /// Moves the cursors right one character.
    override public func moveRight(_ sender: Any?) {
        selectionManager.textSelections.forEach { selection in
            if selection.range.isEmpty {
                moveSelection(selection: selection, direction: .forward, destination: .character)
            } else {
                selection.range.length = 0
            }
        }
        selectionManager.updateSelectionViews()
        scrollSelectionToVisible()
        setNeedsDisplay()
    }

    /// Moves the cursors right one character extending the current selection.
    override public func moveRightAndModifySelection(_ sender: Any?) {
        moveSelections(direction: .forward, destination: .character, modifySelection: true)
    }

    /// Moves the cursors left one word.
    override public func moveWordLeft(_ sender: Any?) {
        moveSelections(direction: .backward, destination: .word)
    }

    /// Moves the cursors left one word extending the current selection.
    override public func moveWordLeftAndModifySelection(_ sender: Any?) {
        moveSelections(direction: .backward, destination: .word, modifySelection: true)
    }

    /// Moves the cursors right one word.
    override public func moveWordRight(_ sender: Any?) {
        moveSelections(direction: .forward, destination: .word)
    }

    /// Moves the cursors right one word extending the current selection.
    override public func moveWordRightAndModifySelection(_ sender: Any?) {
        moveSelections(direction: .forward, destination: .word, modifySelection: true)
    }

    /// Moves the cursors left to the end of the line.
    override public func moveToLeftEndOfLine(_ sender: Any?) {
        moveSelections(direction: .backward, destination: .line)
    }

    /// Moves the cursors left to the end of the line extending the current selection.
    override public func moveToLeftEndOfLineAndModifySelection(_ sender: Any?) {
        moveSelections(direction: .backward, destination: .line, modifySelection: true)
    }

    /// Moves the cursors right to the end of the line.
    override public func moveToRightEndOfLine(_ sender: Any?) {
        moveSelections(direction: .forward, destination: .line)
    }

    /// Moves the cursors right to the end of the line extending the current selection.
    override public func moveToRightEndOfLineAndModifySelection(_ sender: Any?) {
        moveSelections(direction: .forward, destination: .line, modifySelection: true)
    }

    /// Moves the cursors to the beginning of the line, if pressed again selects the next line up.
    override public func moveToBeginningOfParagraph(_ sender: Any?) {
        moveSelections(direction: .up, destination: .line)
    }

    /// Moves the cursors to the beginning of the line, if pressed again selects the next line up extending the current
    /// selection.
    override public func moveToBeginningOfParagraphAndModifySelection(_ sender: Any?) {
        moveSelections(direction: .up, destination: .line, modifySelection: true)
    }

    /// Moves the cursors to the end of the line, if pressed again selects the next line up.
    override public func moveToEndOfParagraph(_ sender: Any?) {
        moveSelections(direction: .down, destination: .line)
    }

    /// Moves the cursors to the end of the line, if pressed again selects the next line up extending the current
    /// selection.
    override public func moveToEndOfParagraphAndModifySelection(_ sender: Any?) {
        moveSelections(direction: .down, destination: .line, modifySelection: true)
    }

    /// Moves the cursors to the beginning of the document.
    override public func moveToBeginningOfDocument(_ sender: Any?) {
        moveSelections(direction: .up, destination: .document)
    }

    /// Moves the cursors to the beginning of the document extending the current selection.
    override public func moveToBeginningOfDocumentAndModifySelection(_ sender: Any?) {
        moveSelections(direction: .up, destination: .document, modifySelection: true)
    }

    /// Moves the cursors to the end of the document.
    override public func moveToEndOfDocument(_ sender: Any?) {
        moveSelections(direction: .down, destination: .document)
    }

    /// Moves the cursors to the end of the document extending the current selection.
    override public func moveToEndOfDocumentAndModifySelection(_ sender: Any?) {
        moveSelections(direction: .down, destination: .document, modifySelection: true)
    }

    /// Moves all selections, determined by the direction and destination provided.
    ///
    /// Also handles updating the selection views and marks the view as needing display.
    ///
    /// - Parameters:
    ///   - direction: The direction to modify all selections.
    ///   - destination: The destination to move the selections by.
    ///   - modifySelection: Set to `true` to modify the selections instead of replacing it.
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
        scrollSelectionToVisible()
        setNeedsDisplay()
    }

    /// Moves a single selection determined by the direction and destination provided.
    /// - Parameters:
    ///   - selection: The selection to modify.
    ///   - direction: The direction to move in.
    ///   - destination: The destination of the move.
    ///   - modifySelection: Set to `true` to modify the selection instead of replacing it.
    fileprivate func moveSelection(
        selection: TextSelectionManager.TextSelection,
        direction: TextSelectionManager.Direction,
        destination: TextSelectionManager.Destination,
        modifySelection: Bool = false
    ) {
        let range = selectionManager.rangeOfSelection(
            from: direction == .forward ? selection.range.max : selection.range.location,
            direction: direction,
            destination: destination,
            suggestedXPos: selection.suggestedXPos
        )
        print(selection.suggestedXPos, layoutManager?.rectForOffset(range.location)?.minX)
        if modifySelection {
            selection.range.formUnion(range)
        } else {
            switch direction {
            case .up:
                selection.suggestedXPos = selection.suggestedXPos ?? layoutManager?.rectForOffset(range.location)?.minX
                selection.range = NSRange(location: range.location, length: 0)
            case .down:
                selection.suggestedXPos = selection.suggestedXPos ?? layoutManager?.rectForOffset(range.max)?.minX
                selection.range = NSRange(location: range.max, length: 0)
            case .backward:
                selection.suggestedXPos = nil
                selection.range = NSRange(location: range.location, length: 0)
            case .forward:
                selection.suggestedXPos = nil
                selection.range = NSRange(location: range.max, length: 0)
            }
        }
    }
}
