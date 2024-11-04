//
//  StyledRangeStore+StyledRun.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 10/25/24

import _RopeModule

extension StyledRangeStore {
    struct StyledRun {
        var length: Int
        let capture: CaptureName?
        let modifiers: CaptureModifierSet

        init(length: Int, capture: CaptureName?, modifiers: CaptureModifierSet) {
            self.length = length
            self.capture = capture
            self.modifiers = modifiers
        }

        static func empty(length: Int) -> Self {
            StyledRun(length: length, capture: nil, modifiers: [])
        }

        /// Compare two styled ranges by their stored styles.
        /// - Parameter other: The range to compare to.
        /// - Returns: The result of the comparison.
        func styleCompare(_ other: Self) -> Bool {
            capture == other.capture && modifiers == other.modifiers
        }
    }
}

extension StyledRangeStore.StyledRun: RopeElement {
    typealias Index = Int

    var summary: Summary { Summary(length: length) }

    @inlinable
    var isEmpty: Bool { length == 0 }

    @inlinable
    var isUndersized: Bool { false } // Never undersized, pseudo-container

    func invariantCheck() {}

    mutating func rebalance(nextNeighbor right: inout Self) -> Bool {
        // Never undersized
        fatalError("Unimplemented")
    }

    mutating func rebalance(prevNeighbor left: inout Self) -> Bool {
        // Never undersized
        fatalError("Unimplemented")
    }

    mutating func split(at index: Self.Index) -> Self {
        assert(index >= 0 && index <= length)
        let tail = Self(length: length - index, capture: capture, modifiers: modifiers)
        length = index
        return tail
    }
}

extension StyledRangeStore.StyledRun {
    struct Summary {
        var length: Int

        init(length: Int) {
            self.length = length
        }
    }
}

extension StyledRangeStore.StyledRun.Summary: RopeSummary {
    // FIXME: This is entirely arbitrary. Benchmark this.
    @inline(__always)
    static var maxNodeSize: Int { 10 }

    @inline(__always)
    static var zero: StyledRangeStore.StyledRun.Summary { Self(length: 0) }

    @inline(__always)
    var isZero: Bool { length == 0 }

    mutating func add(_ other: StyledRangeStore.StyledRun.Summary) {
        length += other.length
    }

    mutating func subtract(_ other: StyledRangeStore.StyledRun.Summary) {
        length -= other.length
    }
}
