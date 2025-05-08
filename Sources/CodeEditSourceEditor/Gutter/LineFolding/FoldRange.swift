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
    /// Ordered array of ranges that are nested in this fold.
    var subFolds: [FoldRange]

    weak var parent: FoldRange?

    init(lineRange: ClosedRange<Int>, range: NSRange, parent: FoldRange?, subFolds: [FoldRange]) {
        self.lineRange = lineRange
        self.range = range
        self.subFolds = subFolds
        self.parent = parent
    }
}
