//
//  TextSelectionManager+Move.swift
//  
//
//  Created by Khan Winter on 9/20/23.
//

import AppKit
import Common

extension TextSelectionManager {
    /// Moves all selections, determined by the direction and destination provided.
    ///
    /// Also handles updating the selection views and marks the view as needing display.
    ///
    /// - Parameters:
    ///   - direction: The direction to modify all selections.
    ///   - destination: The destination to move the selections by.
    ///   - modifySelection: Set to `true` to modify the selections instead of replacing it.
    public func moveSelections(
        direction: TextSelectionManager.Direction,
        destination: TextSelectionManager.Destination,
        modifySelection: Bool = false
    ) {
        textSelections.forEach {
            moveSelection(
                selection: $0,
                direction: direction,
                destination: destination,
                modifySelection: modifySelection
            )
        }
        updateSelectionViews()
        delegate?.setNeedsDisplay()
        NotificationCenter.default.post(Notification(name: TextSelectionManager.selectionChangedNotification))
    }

    /// Moves a single selection determined by the direction and destination provided.
    /// - Parameters:
    ///   - selection: The selection to modify.
    ///   - direction: The direction to move in.
    ///   - destination: The destination of the move.
    ///   - modifySelection: Set to `true` to modify the selection instead of replacing it.
    private func moveSelection(
        selection: TextSelectionManager.TextSelection,
        direction: TextSelectionManager.Direction,
        destination: TextSelectionManager.Destination,
        modifySelection: Bool = false
    ) {
        if !selection.range.isEmpty
            && !modifySelection
            && (direction == .backward || direction == .forward)
            && destination == .character {
            if direction == .forward {
                selection.range.location = selection.range.max
            }
            selection.range.length = 0
            return
        }

        // Find where to modify the selection from.
        let startLocation = findSelectionStartLocation(selection, direction: direction)

        // Update pivot if necessary
        updateSelectionPivot(selection, direction: direction)

        let range = rangeOfSelection(
            from: startLocation,
            direction: direction,
            destination: destination,
            suggestedXPos: selection.suggestedXPos
        )

        // Update the suggested x position
        updateSelectionXPos(selection, newRange: range, direction: direction, destination: destination)

        // Update the selection range
        updateSelectionRange(
            selection,
            newRange: range,
            modifySelection: modifySelection,
            direction: direction,
            destination: destination
        )
    }

    private func findSelectionStartLocation(
        _ selection: TextSelectionManager.TextSelection,
        direction: TextSelectionManager.Direction
    ) -> Int {
        if direction == .forward || (direction == .down && !selection.range.isEmpty) {
            return selection.range.max
        } else {
            return selection.range.location
        }
    }

    private func updateSelectionPivot(
        _ selection: TextSelectionManager.TextSelection,
        direction: TextSelectionManager.Direction
    ) {
        if selection.pivot == nil {
            // TODO: Pivot!!!!
        }
    }

    private func updateSelectionXPos(
        _ selection: TextSelectionManager.TextSelection,
        newRange range: NSRange,
        direction: TextSelectionManager.Direction,
        destination: TextSelectionManager.Destination
    ) {
        switch direction {
        case .up:
            if destination != .line {
                selection.suggestedXPos = selection.suggestedXPos ?? layoutManager?.rectForOffset(range.location)?.minX
            } else {
                selection.suggestedXPos = nil
            }
        case .down:
            if destination == .line {
                selection.suggestedXPos = layoutManager?.rectForOffset(range.max)?.minX
            } else {
                selection.suggestedXPos = selection.suggestedXPos ?? layoutManager?.rectForOffset(range.max)?.minX
            }
        case .forward:
            selection.suggestedXPos = layoutManager?.rectForOffset(range.max)?.minX
        case .backward:
            selection.suggestedXPos = layoutManager?.rectForOffset(range.location)?.minX
        }
    }

    private func updateSelectionRange(
        _ selection: TextSelectionManager.TextSelection,
        newRange range: NSRange,
        modifySelection: Bool,
        direction: TextSelectionManager.Direction,
        destination: TextSelectionManager.Destination
    ) {
        if modifySelection {
            selection.range.formUnion(range)
        } else {
            switch direction {
            case .up, .backward:
                selection.range = NSRange(location: range.location, length: 0)
            case .down, .forward:
                selection.range = NSRange(location: range.max, length: 0)
            }
        }
    }
}
