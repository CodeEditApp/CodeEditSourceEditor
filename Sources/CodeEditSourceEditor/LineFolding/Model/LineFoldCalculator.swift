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

    var rangesPublisher = CurrentValueSubject<LineFoldStorage, Never>(.init(documentLength: 0))

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
            var foldCache: [LineFoldStorage.RawFold] = []
            // Depth: Open range
            var openFolds: [Int: LineFoldStorage.RawFold] = [:]
            var currentDepth: Int = 0
            var iterator = textView.layoutManager.linesInRange(textView.documentRange)

            var lines = self.getMoreLines(
                textView: textView,
                iterator: &iterator,
                previousDepth: currentDepth,
                foldProvider: foldProvider
            )
            while let lineChunk = lines {
                for lineInfo in lineChunk where lineInfo.depth > 0 {
                    // Start a new fold, going deeper to a new depth.
                    if lineInfo.depth > currentDepth {
                        let newFold = LineFoldStorage.RawFold(
                            depth: lineInfo.depth,
                            range: lineInfo.rangeIndice..<lineInfo.rangeIndice
                        )
                        openFolds[newFold.depth] = newFold
                    } else if lineInfo.depth < currentDepth {
                        // End open folds > received depth
                        for openFold in openFolds.values.filter({ $0.depth > lineInfo.depth }) {
                            openFolds.removeValue(forKey: openFold.depth)
                            foldCache.append(
                                LineFoldStorage.RawFold(
                                    depth: openFold.depth,
                                    range: openFold.range.lowerBound..<lineInfo.rangeIndice
                                )
                            )
                        }
                    }

                    currentDepth = lineInfo.depth
                }
                lines = self.getMoreLines(
                    textView: textView,
                    iterator: &iterator,
                    previousDepth: currentDepth,
                    foldProvider: foldProvider
                )
            }

            // Clean up any hanging folds.
            for fold in openFolds.values {
                foldCache.append(
                    LineFoldStorage.RawFold(
                        depth: fold.depth,
                        range: fold.range.lowerBound..<textView.length
                    )
                )
            }

            let storage = LineFoldStorage(
                documentLength: textView.length,
                folds: foldCache.sorted(by: { $0.range.lowerBound < $1.range.lowerBound }),
                collapsedProvider: {
                    Set(
                        textView.layoutManager.attachments
                            .getAttachmentsOverlapping(textView.documentRange)
                            .compactMap { $0.attachment as? LineFoldPlaceholder }
                            .map {
                                LineFoldStorage.DepthStartPair(depth: $0.fold.depth, start: $0.fold.range.lowerBound)
                            }
                    )
                }
            )
            self.rangesPublisher.send(storage)
        }
    }

    private func getMoreLines(
        textView: TextView,
        iterator: inout TextLayoutManager.RangeIterator,
        previousDepth: Int,
        foldProvider: LineFoldProvider
    ) -> [LineFoldProviderLineInfo]? {
        DispatchQueue.main.asyncAndWait {
            var results: [LineFoldProviderLineInfo] = []
            var count = 0
            var previousDepth: Int = previousDepth
            while count < 50, let linePosition = iterator.next() {
                let foldInfo = foldProvider.foldLevelAtLine(
                    lineNumber: linePosition.index,
                    lineRange: linePosition.range,
                    previousDepth: previousDepth,
                    text: textView.textStorage
                )
                results.append(contentsOf: foldInfo)
                count += 1
                previousDepth = foldInfo.max(by: { $0.depth < $1.depth })?.depth ?? previousDepth
            }
            if results.isEmpty && count == 0 {
                return nil
            }
            return results
        }
    }
}
