//
//  TextLayoutManager+Edits.swift
//
//
//  Created by Khan Winter on 9/3/23.
//

import AppKit
import Common

// MARK: - Edits

extension TextLayoutManager: NSTextStorageDelegate {
    /// Notifies the layout manager of an edit.
    ///
    /// Used by the `TextView` to tell the layout manager about any edits that will happen.
    /// Use this to keep the layout manager's line storage in sync with the text storage.
    ///
    /// - Parameters:
    ///   - range: The range of the edit.
    ///   - string: The string to replace in the given range.
    public func willReplaceCharactersInRange(range: NSRange, with string: String) {
        // Loop through each line being replaced in reverse, updating and removing where necessary.
        for linePosition in lineStorage.linesInRange(range).reversed() {
            // Two cases: Updated line, deleted line entirely
            guard let intersection = linePosition.range.intersection(range), !intersection.isEmpty else { continue }
            if intersection == linePosition.range {
                // Delete line
                lineStorage.delete(lineAt: linePosition.range.location)
            } else if intersection.max == linePosition.range.max,
                      let nextLine = lineStorage.getLine(atIndex: linePosition.range.max) {
                // Need to merge line with one after it after updating this line to remove the end of the line
                lineStorage.delete(lineAt: nextLine.range.location)
                let delta = -intersection.length + nextLine.range.length
                if delta != 0 {
                    lineStorage.update(atIndex: linePosition.range.location, delta: delta, deltaHeight: 0)
                }
            } else {
                lineStorage.update(atIndex: linePosition.range.location, delta: -intersection.length, deltaHeight: 0)
            }
        }

        // Loop through each line being inserted, inserting where necessary
        if !string.isEmpty {
            print("Inserting...")
            print(lineStorage.getLine(atIndex: range.location)!.range)
            var index = 0
            while let nextLine = (string as NSString).getNextLine(startingAt: index) {
                print(nextLine)
                index = nextLine.max
            }

            if index < string.lengthOfBytes(using: .utf16) {
                // Get the last line.
                let lastLine = (string as NSString).substring(from: index)
                print("Last line", lastLine, range.location + index)
                lineStorage.update(
                    atIndex: range.location + index,
                    delta: lastLine.lengthOfBytes(using: .utf16),
                    deltaHeight: 0.0
                )
            }
        }

        setNeedsLayout()
    }

    /// This method is to simplify keeping the layout manager in sync with attribute changes in the storage object.
    /// This does not handle cases where characters have been inserted or removed from the storage.
    /// For that, see the `willPerformEdit` method.
    public func textStorage(
        _ textStorage: NSTextStorage,
        didProcessEditing editedMask: NSTextStorageEditActions,
        range editedRange: NSRange,
        changeInLength delta: Int
    ) {
        if editedMask.contains(.editedAttributes) && delta == 0 {
            invalidateLayoutForRange(editedRange)
        }
    }
}
