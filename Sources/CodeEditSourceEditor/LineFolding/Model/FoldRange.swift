//
//  FoldRange.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 5/7/25.
//

import Foundation

/// Represents a folded range
class FoldRange {
    var range: NSRange
    var depth: Int
    var collapsed: Bool

    init(
        range: NSRange,
        depth: Int,
        collapsed: Bool
    ) {
        self.range = range
        self.depth = depth
        self.collapsed = collapsed
    }
}

struct LineFoldStorage: Sendable {
    struct Fold: RangeStoreElement, Sendable {
        var isEmpty: Bool { depth == nil }

        var depth: Int?
        var collapsed: Bool
    }

    struct FoldRunInfo: Equatable, Sendable {
        let depth: Int
        let collapsed: Bool
        let runs: [Range<Int>]
    }

    var storage: RangeStore<Fold>

    init(foldDepths: [(range: Range<Int>, depth: Int)], documentLength: Int) {
        storage = RangeStore<Fold>(documentLength: documentLength)

        for foldDepth in foldDepths {
            storage.set(
                value: Fold(depth: foldDepth.depth, collapsed: false),
                for: foldDepth.range
            )
        }
    }

    func depth(at offset: Int) -> Int? {
        storage.findValue(at: offset)?.depth
    }

    func foldMarkers(for range: ClosedRange<Int>) -> [FoldRange] {
        []
    }

    func collectRuns(forDeepestFoldAt offset: Int) -> FoldRunInfo? {
        let initialIndex = storage.findIndex(at: offset).index
        guard let foldRange = storage.findValue(at: offset),
              let foldDepth = foldRange.depth else {
            return nil
        }

        var runs: [Range<Int>] = []

        func appendRun(_ index: RangeStore<Fold>.Index) {
            let location = storage._guts.offset(of: index, in: RangeStore.OffsetMetric())
            let length = storage._guts[initialIndex].length
            runs.append(location..<(location + length))
        }
        appendRun(initialIndex)

        // Collect up
        if initialIndex != storage._guts.startIndex {
            var index = storage._guts.index(before: initialIndex)
            while index != storage._guts.startIndex,
                  let nextDepth = storage._guts[index].value?.depth,
                    nextDepth >= foldDepth {
                if nextDepth == foldDepth {
                    appendRun(index)
                }
                index = storage._guts.index(before: index)
            }
        }

        // Collect down
        if initialIndex != storage._guts.endIndex {
            var index = storage._guts.index(after: initialIndex)
            while index != storage._guts.endIndex,
                  let nextDepth = storage._guts[index].value?.depth,
                  nextDepth >= foldDepth {
                if nextDepth == foldDepth {
                    appendRun(index)
                }
                index = storage._guts.index(after: index)
            }
        }

        return FoldRunInfo(depth: foldDepth, collapsed: foldRange.collapsed, runs: runs)
    }

    mutating func toggleCollapse(at offset: Int) {
        guard let foldInfo = collectRuns(forDeepestFoldAt: offset) else { return }
        for run in foldInfo.runs {
            storage.set(value: Fold(depth: foldInfo.depth, collapsed: !foldInfo.collapsed), for: run)
        }
    }
}
