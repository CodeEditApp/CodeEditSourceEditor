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
actor LineFoldCalculator {
    weak var foldProvider: LineFoldProvider?
    weak var controller: TextViewController?

    var valueStream: AsyncStream<LineFoldStorage>

    private var valueStreamContinuation: AsyncStream<LineFoldStorage>.Continuation
    private var textChangedTask: Task<Void, Never>?

    init(
        foldProvider: LineFoldProvider?,
        controller: TextViewController,
        textChangedStream: AsyncStream<(NSRange, Int)>
    ) {
        self.foldProvider = foldProvider
        self.controller = controller
        (valueStream, valueStreamContinuation) = AsyncStream<LineFoldStorage>.makeStream()
        Task { await listenToTextChanges(textChangedStream: textChangedStream) }
    }

    deinit {
        textChangedTask?.cancel()
    }

    private func listenToTextChanges(textChangedStream: AsyncStream<(NSRange, Int)>) {
        textChangedTask = Task {
            for await edit in textChangedStream {
                await buildFoldsForDocument(afterEditIn: edit.0, delta: edit.1)
            }
        }
    }

    /// Build out the folds for the entire document.
    ///
    /// For each line in the document, find the indentation level using the ``levelProvider``. At each line, if the
    /// indent increases from the previous line, we start a new fold. If it decreases we end the fold we were in.
    private func buildFoldsForDocument(afterEditIn: NSRange, delta: Int) async {
        guard let controller = self.controller, let foldProvider = self.foldProvider else { return }
        let documentRange = await controller.textView.documentRange
        var foldCache: [LineFoldStorage.RawFold] = []
        // Depth: Open range
        var openFolds: [Int: LineFoldStorage.RawFold] = [:]
        var currentDepth: Int = 0
        var iterator = await controller.textView.layoutManager.linesInRange(documentRange)

        var lines = await self.getMoreLines(
            controller: controller,
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
            lines = await self.getMoreLines(
                controller: controller,
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
                    range: fold.range.lowerBound..<documentRange.length
                )
            )
        }

        let attachments = await controller.textView.layoutManager.attachments
            .getAttachmentsOverlapping(documentRange)
            .compactMap { $0.attachment as? LineFoldPlaceholder }
            .map {
                LineFoldStorage.DepthStartPair(depth: $0.fold.depth, start: $0.fold.range.lowerBound)
            }

        let storage = LineFoldStorage(
            documentLength: foldCache.max(
                by: { $0.range.upperBound < $1.range.upperBound }
            )?.range.upperBound ?? documentRange.length,
            folds: foldCache.sorted(by: { $0.range.lowerBound < $1.range.lowerBound }),
            collapsedProvider: { Set(attachments) }
        )
        valueStreamContinuation.yield(storage)
    }

    @MainActor
    private func getMoreLines(
        controller: TextViewController,
        iterator: inout TextLayoutManager.RangeIterator,
        previousDepth: Int,
        foldProvider: LineFoldProvider
    ) -> [LineFoldProviderLineInfo]? {
        var results: [LineFoldProviderLineInfo] = []
        var count = 0
        var previousDepth: Int = previousDepth
        while count < 50, let linePosition = iterator.next() {
            let foldInfo = foldProvider.foldLevelAtLine(
                lineNumber: linePosition.index,
                lineRange: linePosition.range,
                previousDepth: previousDepth,
                controller: controller
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
