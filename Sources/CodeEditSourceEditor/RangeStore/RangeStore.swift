//
//  RangeStore.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 10/24/24
//

import _RopeModule

/// RangeStore is a container type that allows for setting and querying captures and modifiers for syntax
/// highlighting. The container reflects a text document in that its length needs to be kept up-to-date.
///
/// Internally this class uses a `Rope` from the swift-collections package, allowing for efficient updates and
/// retrievals.
struct RangeStore<Element: StyledRangeStoreElement>: Sendable {
    typealias Run = StyledRangeStoreRun<Element>
    typealias RopeType = Rope<StyledRun>
    typealias Index = RopeType.Index
    var _guts = RopeType()

    var length: Int {
        _guts.count(in: OffsetMetric())
    }

    /// A small performance improvement for multiple identical queries, as often happens when used
    /// in ``StyledRangeContainer``
    private var cache: (range: Range<Int>, runs: [Run])?

    init(documentLength: Int) {
        self._guts = RopeType([StyledRun(length: documentLength, value: nil)])
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
            runs.append(Run(length: run.length - (offset ?? 0), value: run.value))

            index = _guts.index(after: index)
            offset = nil
        }

        return runs
    }

    /// Sets a value for a range.
    /// - Parameters:
    ///   - value: The value to set for the given range.
    ///   - range: The range to write to.
    mutating func set(value: Element, for range: Range<Int>) {
        assert(range.lowerBound >= 0, "Negative lowerBound")
        assert(range.upperBound <= _guts.count(in: OffsetMetric()), "upperBound outside valid range")
        set(runs: [Run(length: range.length, value: value)], for: range)
    }

    /// Replaces a range in the document with an array of runs.
    /// - Parameters:
    ///   - runs: The runs to insert.
    ///   - range: The range to replace.
    mutating func set(runs: [Run], for range: Range<Int>) {
        let gutsRange = 0..<_guts.count(in: OffsetMetric())
        if range.clamped(to: gutsRange) != range {
            let upperBound = range.clamped(to: gutsRange).upperBound
            let missingCharacters = range.upperBound - upperBound
            storageUpdated(replacedCharactersIn: upperBound..<upperBound, withCount: missingCharacters)
        }

        _guts.replaceSubrange(
            range,
            in: OffsetMetric(),
            with: runs.map { StyledRun(length: $0.length, value: $0.value) }
        )

        coalesceNearby(range: range)
        cache = nil
    }
}

// MARK: - Storage Sync

extension RangeStore {
    /// Handles keeping the internal storage in sync with the document.
    mutating func storageUpdated(replacedCharactersIn range: Range<Int>, withCount newLength: Int) {
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
