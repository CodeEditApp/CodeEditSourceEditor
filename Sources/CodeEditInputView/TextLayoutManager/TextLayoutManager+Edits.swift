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
            var index = 0
            while let nextLine = (string as NSString).getNextLine(startingAt: index) {
                let lineRange = NSRange(location: index, length: nextLine.max - index)
                applyLineInsert((string as NSString).substring(with: lineRange) as NSString, at: range.location + index)
                index = nextLine.max
            }

            if index < (string as NSString).length {
                // Get the last line.
                applyLineInsert(
                    (string as NSString).substring(from: index) as NSString,
                    at: range.location + index
                )
            }
        }

        setNeedsLayout()
    }

    /// Applies a line insert to the internal line storage tree.
    /// - Parameters:
    ///   - insertedString: The string being inserted.
    ///   - location: The location the string is being inserted into.
    private func applyLineInsert(_ insertedString: NSString, at location: Int) {
        if lineStorage.count == 0 && lineStorage.length == 0 {
            // The text was completely empty before, insert.
            lineStorage.insert(
                line: TextLine(),
                atIndex: location,
                length: insertedString.length,
                height: estimateLineHeight()
            )
        } else if LineEnding(line: insertedString as String) != nil {
            // Need to split the line inserting into and create a new line with the split section of the line
            guard let linePosition = lineStorage.getLine(atIndex: location) else { return }
            let splitLocation = location + insertedString.length
            let splitLength = linePosition.range.max - location
            let lineDelta = insertedString.length - splitLength // The difference in the line being edited
            if lineDelta != 0 {
                lineStorage.update(atIndex: location, delta: lineDelta, deltaHeight: 0.0)
            }

            lineStorage.insert(
                line: TextLine(),
                atIndex: splitLocation,
                length: splitLength,
                height: estimateLineHeight()
            )
        } else {
            lineStorage.update(atIndex: location, delta: insertedString.length, deltaHeight: 0.0)
        }
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
