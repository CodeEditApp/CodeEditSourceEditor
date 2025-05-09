//
//  FoldRange.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 5/7/25.
//

import Foundation

/// Represents a recursive folded range
class FoldRange {
    var lineRange: ClosedRange<Int>
    var range: NSRange
    var depth: Int
    var collapsed: Bool
    /// Ordered array of ranges that are nested in this fold.
    var subFolds: [FoldRange]

    weak var parent: FoldRange?

    init(
        lineRange: ClosedRange<Int>,
        range: NSRange,
        depth: Int,
        collapsed: Bool,
        parent: FoldRange?,
        subFolds: [FoldRange]
    ) {
        self.lineRange = lineRange
        self.range = range
        self.depth = depth
        self.collapsed = collapsed
        self.subFolds = subFolds
        self.parent = parent
    }
}
