//
//  LineFoldingModel.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 5/7/25.
//

import AppKit
import CodeEditTextView
import Combine

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
    var foldCache: LineFoldStorage = LineFoldStorage(documentLength: 0)
    private var calculator: LineFoldCalculator

    private var textChangedStream: AsyncStream<(NSRange, Int)>
    private var textChangedStreamContinuation: AsyncStream<(NSRange, Int)>.Continuation
    private var cacheListenTask: Task<Void, Never>?

    weak var controller: TextViewController?

    init(controller: TextViewController, foldView: FoldingRibbonView, foldProvider: LineFoldProvider?) {
        self.controller = controller
        (textChangedStream, textChangedStreamContinuation) = AsyncStream<(NSRange, Int)>.makeStream()
        self.calculator = LineFoldCalculator(
            foldProvider: foldProvider,
            controller: controller,
            textChangedStream: textChangedStream
        )
        super.init()
        controller.textView.addStorageDelegate(self)

        cacheListenTask = Task { @MainActor [weak foldView] in
            for await newFolds in await calculator.valueStream {
                foldCache = newFolds
                foldView?.needsDisplay = true
            }
        }
        textChangedStreamContinuation.yield((.zero, 0))
    }

    func getFolds(in range: Range<Int>) -> [FoldRange] {
        foldCache.folds(in: range)
    }

    func textStorage(
        _ textStorage: NSTextStorage,
        didProcessEditing editedMask: NSTextStorageEditActions,
        range editedRange: NSRange,
        changeInLength delta: Int
    ) {
        guard editedMask.contains(.editedCharacters) else {
            return
        }
        foldCache.storageUpdated(editedRange: editedRange, changeInLength: delta)
        textChangedStreamContinuation.yield((editedRange, delta))
    }

    /// Finds the deepest cached depth of the fold for a line number.
    /// - Parameter lineNumber: The line number to query, zero-indexed.
    /// - Returns: The deepest cached depth of the fold if it was found.
    func getCachedDepthAt(lineNumber: Int) -> Int? {
        return getCachedFoldAt(lineNumber: lineNumber)?.depth
    }

    /// Finds the deepest cached fold and depth of the fold for a line number.
    /// - Parameter lineNumber: The line number to query, zero-indexed.
    /// - Returns: The deepest cached fold and depth of the fold if it was found.
    func getCachedFoldAt(lineNumber: Int) -> (range: FoldRange, depth: Int)? {
        guard let lineRange = controller?.textView.layoutManager.textLineForIndex(lineNumber)?.range else { return nil }
        guard let deepestFold = foldCache.folds(in: lineRange.intRange).max(by: { $0.depth < $1.depth }) else {
            return nil
        }
        return (deepestFold, deepestFold.depth)
    }
}
