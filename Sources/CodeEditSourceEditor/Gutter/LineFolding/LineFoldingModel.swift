//
//  LineFoldingModel.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 5/7/25.
//

import AppKit
import CodeEditTextView
import Combine

class LineFoldCalculator {
    weak var foldProvider: LineFoldProvider?
    weak var textView: TextView?

    var rangesPublisher = CurrentValueSubject<[FoldRange], Never>([])

    private let workQueue = DispatchQueue(label: "app.codeedit.line-folds")

    var textChangedReceiver = PassthroughSubject<Void, Never>()
    private var textChangedCancellable: AnyCancellable?

    init(foldProvider: LineFoldProvider?, textView: TextView) {
        self.foldProvider = foldProvider
        self.textView = textView

        textChangedCancellable = textChangedReceiver.throttle(for: 0.1, scheduler: RunLoop.main, latest: true).sink {
            self.buildFoldsForDocument()
        }
    }

    /// Build out the folds for the entire document.
    ///
    /// For each line in the document, find the indentation level using the ``levelProvider``. At each line, if the
    /// indent increases from the previous line, we start a new fold. If it decreases we end the fold we were in.
    private func buildFoldsForDocument() {
        workQueue.async {
            guard let textView = self.textView, let foldProvider = self.foldProvider else { return }
            var foldCache: [FoldRange] = []
            var currentFold: FoldRange?
            var currentDepth: Int = 0
            var iterator = textView.layoutManager.linesInRange(textView.documentRange)

            var lines = self.getMoreLines(textView: textView, iterator: &iterator, foldProvider: foldProvider)
            while !lines.isEmpty {
                for (lineNumber, foldDepth) in lines {
                    // Start a new fold
                    if foldDepth > currentDepth {
                        let newFold = FoldRange(
                            lineRange: (lineNumber - 1)...(lineNumber - 1),
                            range: .zero,
                            parent: currentFold,
                            subFolds: []
                        )

                        if currentFold == nil {
                            foldCache.append(newFold)
                        } else {
                            currentFold?.subFolds.append(newFold)
                        }
                        currentFold = newFold
                    } else if foldDepth < currentDepth {
                        // End this fold
                        if let fold = currentFold {
                            fold.lineRange = fold.lineRange.lowerBound...lineNumber
                        }
                        currentFold = currentFold?.parent
                    }

                    currentDepth = foldDepth
                }
                lines = self.getMoreLines(textView: textView, iterator: &iterator, foldProvider: foldProvider)
            }

            self.rangesPublisher.send(foldCache)
        }
    }

    private func getMoreLines(
        textView: TextView,
        iterator: inout TextLayoutManager.RangeIterator,
        foldProvider: LineFoldProvider
    ) -> [(index: Int, foldDepth: Int)] {
        DispatchQueue.main.asyncAndWait {
            var results: [(index: Int, foldDepth: Int)] = []
            var count = 0
            while count < 50, let linePosition = iterator.next() {
                guard let substring = textView.textStorage.substring(from: linePosition.range) as NSString?,
                      let foldDepth = foldProvider.foldLevelAtLine(
                        linePosition.index,
                        substring: substring
                      ) else {
                    count += 1
                    continue
                }

                results.append((linePosition.index, foldDepth))
                count += 1
            }
            return results
        }
    }
}

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
    @Published var foldCache: [FoldRange] = []
    private var calculator: LineFoldCalculator
    private var cancellable: AnyCancellable?

    weak var textView: TextView?

    init(textView: TextView, foldProvider: LineFoldProvider?) {
        self.textView = textView
        self.calculator = LineFoldCalculator(foldProvider: foldProvider, textView: textView)
        super.init()
        textView.addStorageDelegate(self)
        cancellable = self.calculator.rangesPublisher.receive(on: RunLoop.main).assign(to: \.foldCache, on: self)
        calculator.textChangedReceiver.send()
    }

    func getFolds(in lineRange: ClosedRange<Int>) -> [FoldRange] {
        foldCache.filter({ $0.lineRange.overlaps(lineRange) })
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
        calculator.textChangedReceiver.send()
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
        binarySearchFoldsArray(lineNumber: lineNumber, folds: foldCache, currentDepth: 0, findDeepest: true)
    }
}

// MARK: - Search Folds

private extension LineFoldingModel {
    /// A generic function for searching an ordered array of fold ranges.
    /// - Returns: The found range and depth it was found at, if it exists.
    func binarySearchFoldsArray(
        lineNumber: Int,
        folds: borrowing [FoldRange],
        currentDepth: Int,
        findDeepest: Bool
    ) -> (range: FoldRange, depth: Int)? {
        var low = 0
        var high = folds.count - 1

        while low <= high {
            let mid = (low + high) / 2
            let fold = folds[mid]

            if fold.lineRange.contains(lineNumber) {
                // Search deeper into subFolds, if any
                if findDeepest {
                    return binarySearchFoldsArray(
                        lineNumber: lineNumber,
                        folds: fold.subFolds,
                        currentDepth: currentDepth + 1,
                        findDeepest: findDeepest
                    ) ?? (fold, currentDepth)
                } else {
                    return (fold, currentDepth)
                }
            } else if lineNumber < fold.lineRange.lowerBound {
                high = mid - 1
            } else {
                low = mid + 1
            }
        }
        return nil
    }
}
