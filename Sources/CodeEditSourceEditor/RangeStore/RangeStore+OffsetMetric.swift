//
//  RangeStore+OffsetMetric.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 10/25/24
//

import _RopeModule

extension RangeStore {
    struct OffsetMetric: RopeMetric {
        typealias Element = StyledRun

        func size(of summary: RangeStore.StyledRun.Summary) -> Int {
            summary.length
        }

        func index(at offset: Int, in element: RangeStore.StyledRun) -> Int {
            return offset
        }
    }
}
