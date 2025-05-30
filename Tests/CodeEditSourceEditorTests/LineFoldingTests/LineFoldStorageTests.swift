//
//  LineFoldStorageTests.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 5/29/25.
//

import Testing
@testable import CodeEditSourceEditor

struct LineFoldStorageTests {
    var storage = LineFoldStorage(
        foldDepths: [
            (1..<9, 1),
            (2..<8, 2),
            (5..<6, 3)
        ],
        documentLength: 10
    )

    @Test
    func findDepthAtIndexes() {
        #expect(storage.depth(at: 0) == nil)
        #expect(storage.depth(at: 1) == 1)
        #expect(storage.depth(at: 2) == 2)
        #expect(storage.depth(at: 5) == 3)
        #expect(storage.depth(at: 6) == 2)
        #expect(storage.depth(at: 8) == 1)
        #expect(storage.depth(at: 9) == nil)
    }

    @Test
    func getDijointRunsForDepth() {
        #expect(
            storage.collectRuns(forDeepestFoldAt: 5)
            == LineFoldStorage.FoldRunInfo(depth: 3, collapsed: false, runs: [5..<6])
        )

        #expect(
            storage.collectRuns(forDeepestFoldAt: 2)
            == LineFoldStorage.FoldRunInfo(depth: 2, collapsed: false, runs: [2..<5, 6..<9])
        )

        #expect(
            storage.collectRuns(forDeepestFoldAt: 1)
            == LineFoldStorage.FoldRunInfo(depth: 1, collapsed: false, runs: [1..<2, 8..<9])
        )
    }

    @Test
    mutating func toggleCollapse() {
        storage.toggleCollapse(at: 1)

        #expect(
            storage.collectRuns(forDeepestFoldAt: 1)
            == LineFoldStorage.FoldRunInfo(depth: 1, collapsed: true, runs: [1..<2, 8..<9])
        )
    }
}
