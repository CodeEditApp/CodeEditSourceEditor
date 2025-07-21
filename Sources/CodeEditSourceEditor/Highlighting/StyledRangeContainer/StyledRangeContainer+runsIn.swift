//
//  StyledRangeContainer+runsIn.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 7/18/25.
//

import Foundation

extension StyledRangeContainer {
    /// Coalesces all styled runs into a single continuous array of styled runs.
    ///
    /// When there is an overlapping, conflicting style (eg: provider 2 gives `.comment` to the range `0..<2`, and
    /// provider 1 gives `.string` to `1..<2`), the provider with a lower identifier will be prioritized. In the example
    /// case, the final value would be `0..<1=.comment` and `1..<2=.string`.
    ///
    /// - Parameter range: The range to query.
    /// - Returns: An array of continuous styled runs.
    func runsIn(range: NSRange) -> [RangeStoreRun<StyleElement>] {
        func combineLowerPriority(_ lhs: inout RangeStoreRun<StyleElement>, _ rhs: RangeStoreRun<StyleElement>) {
            lhs.value = lhs.value?.combineLowerPriority(rhs.value) ?? rhs.value
        }

        func combineHigherPriority(_ lhs: inout RangeStoreRun<StyleElement>, _ rhs: RangeStoreRun<StyleElement>) {
            lhs.value = lhs.value?.combineHigherPriority(rhs.value) ?? rhs.value
        }

        // Ordered by priority, lower = higher priority.
        var allRuns = _storage.sorted(by: { $0.key < $1.key }).map { $0.value.runs(in: range.intRange) }

        #if DEBUG
        // ASSERTION: Verify input contract - runs should be in positional order
        for (priority, runs) in allRuns.enumerated() {
            var expectedStart = range.location
            for (runIndex, run) in runs.enumerated() {
                assert(run.length > 0, "Run \(runIndex) in priority \(priority) has non-positive length: \(run.length)")
            }
            // Note: Can't easily verify positional order without knowing absolute positions
            // This would require the RangeStore to provide position info
        }

        // ASSERTION: Verify total length consistency
        let originalTotalLengths = allRuns.map { runs in runs.reduce(0) { $0 + $1.length } }
        for (priority, totalLength) in originalTotalLengths.enumerated() {
            assert(
                totalLength == range.length,
                "Priority \(priority) total length (\(totalLength)) doesn't match expected length (\(range.length))"
            )
        }
        #endif

        var runs: [RangeStoreRun<StyleElement>] = []
        var minValue = allRuns.compactMap { $0.last }.enumerated().min(by: { $0.1.length < $1.1.length })
        var counter = 0

        while let value = minValue {
            // Get minimum length off the end of each array
            let minRunIdx = value.offset
            var minRun = value.element

            assert(minRun.length > 0, "Minimum run has non-positive length: \(minRun.length)")

            for idx in (0..<allRuns.count).reversed() where idx != minRunIdx {
                guard let last = allRuns[idx].last else { continue }

                assert(
                    last.length >= minRun.length,
                    "Run at priority \(idx) length (\(last.length)) is less than minimum length (\(minRun.length))"
                )
                if idx < minRunIdx {
                    combineHigherPriority(&minRun, last)
                } else {
                    combineLowerPriority(&minRun, last)
                }

                if last.length == minRun.length {
                    allRuns[idx].removeLast()
                } else {
                    // safe due to guard a few lines above.
                    allRuns[idx][allRuns[idx].count - 1].subtractLength(minRun)
                }
            }

            if !allRuns[minRunIdx].isEmpty {
                allRuns[minRunIdx].removeLast()
            }

            runs.append(minRun)
            minValue = allRuns.compactMap { $0.last }.enumerated().min(by: { $0.1.length < $1.1.length })

            debugRunState(allRuns, step: counter)
            counter += 1
        }

        assert(runs.allSatisfy({ $0.length > 0 }), "Empty or negative lengths are not allowed")

        return runs.reversed()
    }

#if DEBUG
    private func debugRunState(_ allRuns: [[RangeStoreRun<StyleElement>]], step: Int) {
        print("=== Debug Step \(step) ===")
        for (priority, runs) in allRuns.enumerated() {
            let lengths = runs.map { $0.length }
            let totalLength = lengths.reduce(0, +)
            print("Priority \(priority): lengths=\(lengths), total=\(totalLength)")
        }
        print()
    }
#endif
}
