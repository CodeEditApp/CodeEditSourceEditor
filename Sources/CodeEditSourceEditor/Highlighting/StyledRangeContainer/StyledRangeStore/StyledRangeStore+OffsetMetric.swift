//
//  StyledRangeStore+OffsetMetric.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 10/25/24
//

import _RopeModule

extension StyledRangeStore {
    struct OffsetMetric: RopeMetric {
        typealias Element = StyledRun

        func size(of summary: StyledRangeStore.StyledRun.Summary) -> Int {
            summary.length
        }

        func index(at offset: Int, in element: StyledRangeStore.StyledRun) -> Int {
            return offset
        }
    }
}
