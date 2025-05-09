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
    private struct LineInfo {
        let lineNumber: Int
        let providerInfo: LineFoldProviderLineInfo
        let collapsed: Bool
    }

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

            var lines = self.getMoreLines(
                textView: textView,
                iterator: &iterator,
                lastDepth: currentDepth,
                foldProvider: foldProvider
            )
            while let lineChunk = lines {
                for lineInfo in lineChunk {
                    // Start a new fold, going deeper to a new depth.
                    if lineInfo.providerInfo.depth > currentDepth {
                        let newFold = FoldRange(
                            lineRange: lineInfo.lineNumber...lineInfo.lineNumber,
                            range: NSRange(location: lineInfo.providerInfo.rangeIndice, length: 0),
                            depth: lineInfo.providerInfo.depth,
                            collapsed: lineInfo.collapsed,
                            parent: currentFold,
                            subFolds: []
                        )

                        if currentFold == nil {
                            foldCache.append(newFold)
                        } else {
                            currentFold?.subFolds.append(newFold)
                        }
                        currentFold = newFold
                    } else if lineInfo.providerInfo.depth < currentDepth {
                        // End this fold, go shallower "popping" folds deeper than the new depth
                        while let fold = currentFold, fold.depth > lineInfo.providerInfo.depth {
                            // close this fold at the current line
                            fold.lineRange = fold.lineRange.lowerBound...lineInfo.lineNumber
                            fold.range = NSRange(start: fold.range.location, end: lineInfo.providerInfo.rangeIndice)
                            // move up
                            currentFold = fold.parent
                        }
                    }

                    currentDepth = lineInfo.providerInfo.depth
                }
                lines = self.getMoreLines(
                    textView: textView,
                    iterator: &iterator,
                    lastDepth: currentDepth,
                    foldProvider: foldProvider
                )
            }

            // Clean up any hanging folds.
            while let fold = currentFold {
                fold.lineRange = fold.lineRange.lowerBound...textView.layoutManager.lineCount - 1
                fold.range = NSRange(start: fold.range.location, end: textView.documentRange.length)
                currentFold = fold.parent
            }

            self.rangesPublisher.send(foldCache)
        }
    }

    private func getMoreLines(
        textView: TextView,
        iterator: inout TextLayoutManager.RangeIterator,
        lastDepth: Int,
        foldProvider: LineFoldProvider
    ) -> [LineInfo]? {
        DispatchQueue.main.asyncAndWait {
            var results: [LineInfo] = []
            var count = 0
            var lastDepth = lastDepth
            while count < 50, let linePosition = iterator.next() {
                guard let foldInfo = foldProvider.foldLevelAtLine(
                    lineNumber: linePosition.index,
                    lineRange: linePosition.range,
                    currentDepth: lastDepth,
                    text: textView.textStorage
                ) else {
                    count += 1
                    continue
                }
                let attachments = textView.layoutManager.attachments
                    .getAttachmentsOverlapping(linePosition.range)
                    .compactMap({ $0.attachment as? LineFoldPlaceholder })

                results.append(
                    LineInfo(
                        lineNumber: linePosition.index,
                        providerInfo: foldInfo,
                        collapsed: !attachments.isEmpty
                    )
                )
                count += 1
                lastDepth = foldInfo.depth
            }
            if results.isEmpty && count == 0 {
                return nil
            }
            return results
        }
    }
}
