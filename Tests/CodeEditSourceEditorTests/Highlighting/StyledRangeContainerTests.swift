import XCTest
@testable import CodeEditSourceEditor

final class StyledRangeContainerTests: XCTestCase {
    typealias Run = HighlightedRun

    func test_init() {
        let providers = [0, 1]
        let store = StyledRangeContainer(documentLength: 100, providers: providers)

        // Have to do string conversion due to missing Comparable conformance pre-macOS 14
        XCTAssertEqual(store._storage.keys.sorted(), providers)
        XCTAssert(store._storage.values.allSatisfy({ $0.length == 100 }), "One or more providers have incorrect length")
    }

    func test_setHighlights() {
        let providers = [0, 1]
        let store = StyledRangeContainer(documentLength: 100, providers: providers)

        store.applyHighlightResult(
            provider: providers[0],
            highlights: [HighlightRange(range: NSRange(location: 40, length: 10), capture: .comment)],
            rangeToHighlight: NSRange(location: 0, length: 100)
        )

        XCTAssertNotNil(store._storage[providers[0]])
        XCTAssertEqual(store._storage[providers[0]]!.count, 3)
        XCTAssertEqual(store._storage[providers[0]]!.runs(in: 0..<100)[0].capture, nil)
        XCTAssertEqual(store._storage[providers[0]]!.runs(in: 0..<100)[1].capture, .comment)
        XCTAssertEqual(store._storage[providers[0]]!.runs(in: 0..<100)[2].capture, nil)

        XCTAssertEqual(
            store.runsIn(range: NSRange(location: 0, length: 100)),
            [
                Run(length: 40, capture: nil, modifiers: []),
                Run(length: 10, capture: .comment, modifiers: []),
                Run(length: 50, capture: nil, modifiers: [])
            ]
        )
    }

    func test_overlappingRuns() {
        
    }
}
