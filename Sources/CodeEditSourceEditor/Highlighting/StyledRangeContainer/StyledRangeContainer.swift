//
//  StyledRangeContainer.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 10/13/24.
//

import Foundation

@MainActor
protocol StyledRangeContainerDelegate: AnyObject {
    func styleContainerDidUpdate(in range: NSRange)
}

/// Stores styles for any number of style providers. Provides an API for providers to store their highlights, and for
/// the overlapping highlights to be queried for a final highlight pass.
///
/// See ``runsIn(range:)`` for more details on how conflicting highlights are handled.
@MainActor
class StyledRangeContainer {
    var _storage: [ProviderID: StyledRangeStore] = [:]
    weak var delegate: StyledRangeContainerDelegate?

    /// Initialize the container with a list of provider identifiers. Each provider is given an id, they should be
    /// passed on here so highlights can be associated with a provider for conflict resolution.
    /// - Parameters:
    ///   - documentLength: The length of the document.
    ///   - providers: An array of identifiers given to providers.
    init(documentLength: Int, providers: [ProviderID]) {
        for provider in providers {
            _storage[provider] = StyledRangeStore(documentLength: documentLength)
        }
    }

    /// Coalesces all styled runs into a single continuous array of styled runs.
    ///
    /// When there is an overlapping, conflicting style (eg: provider 2 gives `.comment` to the range `0..<2`, and
    /// provider 1 gives `.string` to `1..<2`), the provider with a lower identifier will be prioritized. In the example
    /// case, the final value would be `0..<1=.comment` and `1..<2=.string`.
    ///
    /// - Parameter range: The range to query.
    /// - Returns: An array of continuous styled runs.
    func runsIn(range: NSRange) -> [StyledRangeStoreRun] {
        // Ordered by priority, lower = higher priority.
        var allRuns = _storage.sorted(by: { $0.key < $1.key }).map { $0.value.runs(in: range.intRange) }
        var runs: [StyledRangeStoreRun] = []

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
    /// Applies a highlight result from a highlight provider to the storage container.
    /// - Parameters:
    ///   - provider: The provider sending the highlights.
    ///   - highlights: The highlights provided. These cannot be outside the range to highlight, must be ordered by
    ///                 position, but do not need to be continuous. Ranges not included in these highlights will be
    ///                 saved as empty.
    ///   - rangeToHighlight: The range to apply the highlights to.
    func applyHighlightResult(provider: ProviderID, highlights: [HighlightRange], rangeToHighlight: NSRange) {
        assert(rangeToHighlight != .notFound, "NSNotFound is an invalid highlight range")
        guard let storage = _storage[provider] else {
            assertionFailure("No storage found for the given provider: \(provider)")
            return
        }
        var runs: [StyledRangeStoreRun] = []
        var lastIndex = rangeToHighlight.lowerBound

        for highlight in highlights {
            if highlight.range.lowerBound > lastIndex {
                runs.append(.empty(length: highlight.range.lowerBound - lastIndex))
            } else if highlight.range.lowerBound < lastIndex {
                continue // Skip! Overlapping
            }
            runs.append(
                StyledRangeStoreRun(
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
        delegate?.styleContainerDidUpdate(in: rangeToHighlight)
    }
}
