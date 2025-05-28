//
//  StyledRangeStore+FindIndex.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 1/6/25.
//

extension StyledRangeStore {
    /// Finds a Rope index, given a string offset.
    /// - Parameter offset: The offset to query for.
    /// - Returns: The index of the containing element in the rope.
    func findIndex(at offset: Int) -> (index: Index, remaining: Int) {
        _guts.find(at: offset, in: OffsetMetric(), preferEnd: false)
    }
}
