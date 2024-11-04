//
//  StyledRangeContainer.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 10/13/24.
//

import Foundation

class StyledRangeContainer {
    var _storage: [ProviderID: StyledRangeStore] = [:]

    init(documentLength: Int, providers: [ProviderID]) {
        for provider in providers {
            _storage[provider] = StyledRangeStore(documentLength: documentLength)
        }
    }

    func runsIn(range: NSRange) -> [HighlightedRun] {
        // Ordered by priority, lower = higher priority.
        var allRuns = _storage.sorted(by: { $0.key < $1.key }).map { $0.value.runs(in: range.intRange) }
        var runs: [HighlightedRun] = []

        var minValue = allRuns.compactMap { $0.last }.enumerated().min(by: { $0.1.length < $1.1.length })

        while let value = minValue {
            // Get minimum length off the end of each array
            let minRunIdx = value.offset
            var minRun = value.element

            for idx in (0..<allRuns.count).reversed() where idx != minRunIdx {
                guard let last = allRuns[idx].last else { continue }
                if idx < minRunIdx {
                    minRun.combineHigherPriority(last)
                } else {
                    minRun.combineLowerPriority(last)
                }

                if last.length == minRun.length {
                    allRuns[idx].removeLast()
                } else {
                    // safe due to guard a few lines above.
                    allRuns[idx][allRuns[idx].count - 1].subtractLength(minRun)
                }
            }

            allRuns[minRunIdx].removeLast()

            runs.append(minRun)
            minValue = allRuns.compactMap { $0.last }.enumerated().min(by: { $0.1.length < $1.1.length })
        }

        return runs.reversed()
    }

    func storageUpdated(replacedContentIn range: Range<Int>, withCount newLength: Int) {
        _storage.values.forEach {
            $0.storageUpdated(replacedCharactersIn: range, withCount: newLength)
        }
    }
}

extension StyledRangeContainer: HighlightProviderStateDelegate {
    func applyHighlightResult(provider: ProviderID, highlights: [HighlightRange], rangeToHighlight: NSRange) {
        assert(rangeToHighlight != .notFound, "NSNotFound is an invalid highlight range")
        guard let storage = _storage[provider] else {
            assertionFailure("No storage found for the given provider: \(provider)")
            return
        }
        var runs: [HighlightedRun] = []
        var lastIndex = rangeToHighlight.lowerBound

        for highlight in highlights {
            if highlight.range.lowerBound != lastIndex {
                runs.append(.empty(length: highlight.range.lowerBound - lastIndex))
            }
            runs.append(
                HighlightedRun(
                    length: highlight.range.length,
                    capture: highlight.capture,
                    modifiers: highlight.modifiers
                )
            )
            lastIndex = highlight.range.max
        }

        if lastIndex != rangeToHighlight.upperBound {
            runs.append(.empty(length: rangeToHighlight.upperBound - lastIndex))
        }

        storage.set(runs: runs, for: rangeToHighlight.intRange)
    }
}
