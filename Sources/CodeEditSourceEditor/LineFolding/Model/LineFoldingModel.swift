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
    @Published var foldCache: Atomic<[FoldRange]> = Atomic([])
    private var cacheLock = NSLock()
    private var calculator: LineFoldCalculator
    private var cancellable: AnyCancellable?

    weak var textView: TextView?

    init(textView: TextView, foldProvider: LineFoldProvider?) {
        self.textView = textView
        self.calculator = LineFoldCalculator(foldProvider: foldProvider, textView: textView)
        super.init()
        textView.addStorageDelegate(self)
        cancellable = self.calculator.rangesPublisher.receive(on: RunLoop.main).sink { newFolds in
            self.foldCache.mutate { $0 = newFolds }
        }
        calculator.textChangedReceiver.send((.zero, 0))
    }

    func getFolds(in lineRange: ClosedRange<Int>) -> [FoldRange] {
//        foldCache.withValue { $0.filter({ $0.lineRange.overlaps(lineRange) }) }
        []
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
        calculator.textChangedReceiver.send((editedRange, delta))
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
//        foldCache.withValue { foldCache in
//            binarySearchFoldsArray(lineNumber: lineNumber, folds: foldCache, currentDepth: 0, findDeepest: true)
//        }
        nil
    }
}
