//
//  LineFoldingModel.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 5/7/25.
//

import AppKit
import CodeEditTextView

/// # Basic Premise
///
/// We need to update, delete, or add fold ranges in the invalidated lines.
///
/// # Implementation
///
/// - For each line in the document, put its indent level into a list.
/// - Loop through the list, creating nested folds as indents go up and down.
///
class LineFoldingModel: NSObject, NSTextStorageDelegate {
    /// An ordered tree of fold ranges in a document. Can be traversed using ``FoldRange/parent``
    /// and ``FoldRange/subFolds``.
    private var foldCache: [FoldRange] = []

    weak var levelProvider: LineFoldProvider?
    weak var textView: TextView?

    init(textView: TextView, levelProvider: LineFoldProvider?) {
        self.textView = textView
        self.levelProvider = levelProvider
        super.init()
        textView.addStorageDelegate(self)
        buildFoldsForDocument()
    }

    func folds(in lineRange: ClosedRange<Int>) -> [FoldRange] {
        foldCache.filter({ $0.lineRange.overlaps(lineRange) })
    }

    func buildFoldsForDocument() {
        guard let textView, let levelProvider else { return }
        foldCache.removeAll(keepingCapacity: true)

        var currentFold: FoldRange?
        var currentDepth: Int = 0
        for linePosition in textView.layoutManager.linesInRange(textView.documentRange) {
            guard let foldDepth = levelProvider.foldLevelAtLine(
                linePosition.index,
                layoutManager: textView.layoutManager,
                textStorage: textView.textStorage
            ) else {
                continue
            }
            // Start a new fold
            if foldDepth > currentDepth {
                let newFold = FoldRange(
                    lineRange: (linePosition.index - 1)...(linePosition.index - 1),
                    range: .zero,
                    parent: currentFold,
                    subFolds: []
                )

                if currentDepth == 0 {
                    foldCache.append(newFold)
                }
                currentFold?.subFolds.append(newFold)
                currentFold = newFold
            } else if foldDepth < currentDepth {
                // End this fold
                if let fold = currentFold {
                    fold.lineRange = fold.lineRange.lowerBound...linePosition.index

                    if foldDepth == 0 {
                        currentFold = nil
                    }
                }
                currentFold = currentFold?.parent
            }

            currentDepth = foldDepth
        }
    }

    func invalidateLine(lineNumber: Int) {
        // TODO: Check if we need to rebuild, or even better, incrementally update the tree.

        // Temporary
        buildFoldsForDocument()
    }

    func textStorage(
        _ textStorage: NSTextStorage,
        didProcessEditing editedMask: NSTextStorageEditActions,
        range editedRange: NSRange,
        changeInLength delta: Int
    ) {
        guard editedMask.contains(.editedCharacters),
              let lineNumber = textView?.layoutManager.textLineForOffset(editedRange.location)?.index else {
            return
        }
        invalidateLine(lineNumber: lineNumber)
    }
}

// MARK: - Search Folds

private extension LineFoldingModel {
    /// Finds the deepest cached depth of the fold for a line number.
    /// - Parameter lineNumber: The line number to query, zero-indexed.
    /// - Returns: The deepest cached depth of the fold if it was found.
    func getCachedDepthAt(lineNumber: Int) -> Int? {
        return findCachedFoldAt(lineNumber: lineNumber)?.depth
    }

    /// Finds the deepest cached fold and depth of the fold for a line number.
    /// - Parameter lineNumber: The line number to query, zero-indexed.
    /// - Returns: The deepest cached fold and depth of the fold if it was found.
    func findCachedFoldAt(lineNumber: Int) -> (range: FoldRange, depth: Int)? {
        binarySearchFoldsArray(lineNumber: lineNumber, folds: foldCache, currentDepth: 0)
    }

    /// A generic function for searching an ordered array of fold ranges.
    /// - Returns: The found range and depth it was found at, if it exists.
    func binarySearchFoldsArray(
        lineNumber: Int,
        folds: borrowing [FoldRange],
        currentDepth: Int
    ) -> (range: FoldRange, depth: Int)? {
        var low = 0
        var high = folds.count - 1

        while low <= high {
            let mid = (low + high) / 2
            let fold = folds[mid]

            if fold.lineRange.contains(lineNumber) {
                // Search deeper into subFolds, if any
                return binarySearchFoldsArray(
                    lineNumber: lineNumber,
                    folds: fold.subFolds,
                    currentDepth: currentDepth + 1
                ) ?? (fold, currentDepth)
            } else if lineNumber < fold.lineRange.lowerBound {
                high = mid - 1
            } else {
                low = mid + 1
            }
        }
        return nil
    }
}
