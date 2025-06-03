//
//  LineFoldStorage.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 5/7/25.
//
import _RopeModule
import Foundation

/// Represents a single fold region with stable identifier and collapse state
struct FoldRange: Sendable, Equatable {
    typealias FoldIdentifier = UInt32

    let id: FoldIdentifier
    let depth: Int
    let range: Range<Int>
    var isCollapsed: Bool
}

/// Represents a single fold run with stable identifier and collapse state
struct FoldRun: Sendable {
    let id: FoldRange.FoldIdentifier
    let depth: Int
    let range: Range<Int>
    let isCollapsed: Bool
}

/// Sendable data model for code folding using RangeStore
struct LineFoldStorage: Sendable {
    /// A temporary fold representation without stable ID
    struct RawFold: Sendable {
        let depth: Int
        let range: Range<Int>
    }

    struct DepthStartPair: Hashable {
        let depth: Int
        let start: Int
    }

    /// Element stored in RangeStore: holds reference to a fold region
    struct FoldStoreElement: RangeStoreElement, Sendable {
        let id: FoldRange.FoldIdentifier
        let depth: Int

        var isEmpty: Bool { false }
    }

    private var idCounter = FoldRange.FoldIdentifier.zero
    private var store: RangeStore<FoldStoreElement>
    private var foldRanges: [FoldRange.FoldIdentifier: FoldRange] = [:]

    /// Initialize with the full document length
    init(documentLength: Int, folds: [RawFold] = [], collapsedProvider: () -> Set<DepthStartPair> = { [] }) {
        self.store = RangeStore<FoldStoreElement>(documentLength: documentLength)
        self.updateFolds(from: folds, collapsedProvider: collapsedProvider)
    }

    private mutating func nextFoldId() -> FoldRange.FoldIdentifier {
        idCounter += 1
        return idCounter
    }

    /// Replace all fold data from raw folds, preserving collapse state via callback
    /// - Parameter rawFolds: newly computed folds (depth + range)
    /// - Parameter collapsedProvider: callback returning current collapsed ranges/depths
    mutating func updateFolds(from rawFolds: [RawFold], collapsedProvider: () -> Set<DepthStartPair>) {
        // Build reuse map by start+depth, carry over collapse state
        var reuseMap: [DepthStartPair: FoldRange] = [:]
        for region in foldRanges.values {
            reuseMap[DepthStartPair(depth: region.depth, start: region.range.lowerBound)] = region
        }

        // Determine which ranges are currently collapsed
        let collapsedSet = collapsedProvider()

        // Build new regions
        foldRanges.removeAll(keepingCapacity: true)
        store = RangeStore<FoldStoreElement>(documentLength: store.length)

        for raw in rawFolds {
            let key = DepthStartPair(depth: raw.depth, start: raw.range.lowerBound)
            // reuse id and collapse state if available
            let prior = reuseMap[key]
            let id = prior?.id ?? nextFoldId()
            let wasCollapsed = prior?.isCollapsed ?? false
            // override collapse if provider says so
            let isCollapsed = collapsedSet.contains(key) || wasCollapsed
            let fold = FoldRange(id: id, depth: raw.depth, range: raw.range, isCollapsed: isCollapsed)

            foldRanges[id] = fold
            let elem = FoldStoreElement(id: id, depth: raw.depth)
            store.set(value: elem, for: raw.range)
        }
    }

    /// Keep folding offsets in sync after text edits
    mutating func storageUpdated(editedRange: NSRange, changeInLength delta: Int) {
        store.storageUpdated(editedRange: editedRange, changeInLength: delta)
    }

    /// Query a document subrange and return all folds as an ordered list by start position
    func folds(in queryRange: Range<Int>) -> [FoldRange] {
        let runs = store.runs(in: queryRange.clamped(to: 0..<store.length))
        var alreadyReturnedIDs: Set<FoldRange.FoldIdentifier> = []
        var result: [FoldRange] = []

        for run in runs {
            if let elem = run.value, !alreadyReturnedIDs.contains(elem.id), let range = foldRanges[elem.id] {
                result.append(
                    FoldRange(
                        id: elem.id,
                        depth: elem.depth,
                        range: range.range,
                        isCollapsed: range.isCollapsed
                    )
                )
                alreadyReturnedIDs.insert(elem.id)
            }
        }

        return result.sorted { $0.range.lowerBound < $1.range.lowerBound }
//        let runs = store.runs(in: queryRange.clamped(to: 0..<store.length))
//        var currentLocation = queryRange.lowerBound
//        return runs.compactMap { run in
//            defer {
//                currentLocation += run.length
//            }
//            guard let value = run.value else { return nil }
//            return FoldRun(
//                id: value.id,
//                depth: value.depth,
//                range: currentLocation..<(currentLocation + run.length),
//                isCollapsed: foldRanges[value.id]?.isCollapsed ?? false
//            )
//        }
    }

    /// Given a depth and a location, return the full original fold region
    func fullFoldRegion(at location: Int, depth: Int) -> FoldRange? {
        guard let elem = store.findValue(at: location), elem.depth == depth else {
            return nil
        }
        return foldRanges[elem.id]
    }
}
