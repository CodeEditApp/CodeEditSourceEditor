//
//  LineFoldCalculator.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 5/9/25.
//

import AppKit
import CodeEditTextView
import Combine

/// A utility that calculates foldable line ranges in a text document based on indentation depth.
///
/// `LineFoldCalculator` observes text edits and rebuilds fold regions asynchronously.
/// Fold information is emitted via `rangesPublisher`.
/// Notify the calculator it should re-calculate
class LineFoldCalculator {
    weak var foldProvider: LineFoldProvider?
    weak var textView: TextView?

    var rangesPublisher = CurrentValueSubject<[FoldRange], Never>([])

    private let workQueue = DispatchQueue.global(qos: .default)

    var textChangedReceiver = PassthroughSubject<(NSRange, Int), Never>()
    private var textChangedCancellable: AnyCancellable?

    init(foldProvider: LineFoldProvider?, textView: TextView) {
        self.foldProvider = foldProvider
        self.textView = textView

        textChangedCancellable = textChangedReceiver
            .throttle(for: 0.1, scheduler: RunLoop.main, latest: true)
            .sink { edit in
                self.buildFoldsForDocument(afterEditIn: edit.0, delta: edit.1)
            }
    }

    /// Build out the folds for the entire document.
    ///
    /// For each line in the document, find the indentation level using the ``levelProvider``. At each line, if the
    /// indent increases from the previous line, we start a new fold. If it decreases we end the fold we were in.
    private func buildFoldsForDocument(afterEditIn: NSRange, delta: Int) {
        workQueue.async {
            guard let textView = self.textView, let foldProvider = self.foldProvider else { return }
            var foldCache: [FoldRange] = []
            var currentFold: FoldRange?
            var currentDepth: Int = 0
            var iterator = textView.layoutManager.linesInRange(textView.documentRange)

            var lines = self.getMoreLines(textView: textView, iterator: &iterator, foldProvider: foldProvider)
            while let lineChunk = lines {
                for (lineNumber, foldDepth) in lineChunk {
                    // Start a new fold, going deeper to a new depth.
                    if foldDepth > currentDepth {
                        let newFold = FoldRange(
                            lineRange: (lineNumber - 1)...(lineNumber - 1),
                            range: .zero,
                            depth: foldDepth,
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
                        // End this fold, go shallower "popping" folds deeper than the new depth
                        while let fold = currentFold, fold.depth > foldDepth {
                            // close this fold at the current line
                            fold.lineRange = fold.lineRange.lowerBound...lineNumber
                            // move up
                            currentFold = fold.parent
                        }
                    }

                    currentDepth = foldDepth
                }
                lines = self.getMoreLines(textView: textView, iterator: &iterator, foldProvider: foldProvider)
            }

            // Clean up any hanging folds.
            while let fold = currentFold {
                fold.lineRange = fold.lineRange.lowerBound...textView.layoutManager.lineCount
                currentFold = fold.parent
            }

            self.rangesPublisher.send(foldCache)
        }
    }

    private func getMoreLines(
        textView: TextView,
        iterator: inout TextLayoutManager.RangeIterator,
        foldProvider: LineFoldProvider
    ) -> [(index: Int, foldDepth: Int)]? {
        DispatchQueue.main.asyncAndWait {
            var results: [(index: Int, foldDepth: Int)] = []
            var count = 0
            while count < 50, let linePosition = iterator.next() {
                guard textView.textStorage.length <= linePosition.range.max,
                      let substring = textView.textStorage.substring(from: linePosition.range) as NSString?,
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
            if results.isEmpty && count == 0 {
                return nil
            }
            return results
        }
    }
}
