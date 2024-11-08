//
//  StyledRangeStore.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 10/24/24
//

import _RopeModule

/// StyledRangeStore is a container type that allows for setting and querying captures and modifiers for syntax
/// highlighting. The container reflects a text document in that its length needs to be kept up-to-date.
///
/// Internally this class uses a `Rope` from the swift-collections package, allowing for efficient updates and
/// retrievals.
final class StyledRangeStore {
    typealias Run = HighlightedRun
    typealias Index = Rope<StyledRun>.Index
    var _guts = Rope<StyledRun>()

    /// A small performance improvement for multiple identical queries, as often happens when used
    /// in ``StyledRangeContainer``
    private var cache: (range: Range<Int>, runs: [Run])?

    init(documentLength: Int) {
        self._guts = Rope([StyledRun(length: documentLength, capture: nil, modifiers: [])])
    }

    // MARK: - Core
    
    /// Find all runs in a range.
    /// - Parameter range: The range to query.
    /// - Returns: A continuous array of runs representing the queried range.
    func runs(in range: Range<Int>) -> [Run] {
        assert(range.lowerBound >= 0, "Negative lowerBound")
        assert(range.upperBound <= _guts.count(in: OffsetMetric()), "upperBound outside valid range")
        if let cache, cache.range == range {
            return cache.runs
        }

        var runs = [Run]()

        var index = findIndex(at: range.lowerBound).index
        var offset: Int? = range.lowerBound - _guts.offset(of: index, in: OffsetMetric())

        while index < _guts.endIndex {
            let run = _guts[index]
            runs.append(Run(length: run.length - (offset ?? 0), capture: run.capture, modifiers: run.modifiers))

            index = _guts.index(after: index)
            offset = nil
        }

        return runs
    }
    
    /// Sets a capture and modifiers for a range.
    /// - Parameters:
    ///   - capture: The capture to set.
    ///   - modifiers: The modifiers to set.
    ///   - range: The range to write to.
    func set(capture: CaptureName, modifiers: CaptureModifierSet, for range: Range<Int>) {
        assert(range.lowerBound >= 0, "Negative lowerBound")
        assert(range.upperBound <= _guts.count(in: OffsetMetric()), "upperBound outside valid range")
        set(runs: [Run(length: range.length, capture: capture, modifiers: modifiers)], for: range)
    }
    
    /// Replaces a range in the document with an array of runs.
    /// - Parameters:
    ///   - runs: The runs to insert.
    ///   - range: The range to replace.
    func set(runs: [Run], for range: Range<Int>) {
        _guts.replaceSubrange(
            range,
            in: OffsetMetric(),
            with: runs.map { StyledRun(length: $0.length, capture: $0.capture, modifiers: $0.modifiers) }
        )

        coalesceNearby(range: range)
        cache = nil
    }
}

// MARK: - Storage Sync

extension StyledRangeStore {
    /// Handles keeping the internal storage in sync with the document.
    func storageUpdated(replacedCharactersIn range: Range<Int>, withCount newLength: Int) {
        assert(range.lowerBound >= 0, "Negative lowerBound")
        assert(range.upperBound <= _guts.count(in: OffsetMetric()), "upperBound outside valid range")

        if newLength != 0 {
            _guts.replaceSubrange(range, in: OffsetMetric(), with: [.empty(length: newLength)])
        } else {
            _guts.removeSubrange(range, in: OffsetMetric())
        }

        if _guts.count > 0 {
            // Coalesce nearby items if necessary.
            coalesceNearby(range: Range(lowerBound: range.lowerBound, length: newLength))
        }

        cache = nil
    }
}
