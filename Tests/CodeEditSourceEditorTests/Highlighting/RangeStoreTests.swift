import XCTest
@testable import CodeEditSourceEditor

class RangeStoreTests: XCTestCase {
    func test_insertRange() {
        let rangeStore = RangeStore<String>()
        let range1 = 0..<5
        let range2 = 5..<10
        let range3 = 10..<15

        rangeStore.insert(value: "Value 1", range: range1)
        rangeStore.insert(value: "Value 2", range: range2)
        rangeStore.insert(value: "Value 3", range: range3)

        let results = rangeStore.ranges(overlapping: 0..<20)
        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(results[0].value, "Value 1")
        XCTAssertEqual(results[1].value, "Value 2")
        XCTAssertEqual(results[2].value, "Value 3")
    }

    func test_deleteRange() {
        let rangeStore = RangeStore<String>()
        let range1 = 0..<5
        let range2 = 5..<10

        rangeStore.insert(value: "Value 1", range: range1)
        rangeStore.insert(value: "Value 2", range: range2)

        XCTAssertTrue(rangeStore.delete(range: range2))

        let resultsAfterDelete = rangeStore.ranges(overlapping: 0..<20)
        XCTAssertEqual(resultsAfterDelete.count, 1)
        XCTAssertEqual(resultsAfterDelete[0].value, "Value 1")
    }

    func test_insertMultipleRangesThenDelete() {
        let rangeStore = RangeStore<String>()
        let range1 = 0..<5
        let range2 = 5..<10
        let range3 = 10..<15

        rangeStore.insert(value: "Value 1", range: range1)
        rangeStore.insert(value: "Value 2", range: range2)
        rangeStore.insert(value: "Value 3", range: range3)

        XCTAssertTrue(rangeStore.delete(range: range1))
        XCTAssertTrue(rangeStore.delete(range: range2))
        XCTAssertTrue(rangeStore.delete(range: range3))

        let results = rangeStore.ranges(overlapping: 0..<20)
        XCTAssertTrue(results.isEmpty)
    }

    func test_searchRange() {
        let rangeStore = RangeStore<String>()
        let range1 = 0..<5
        let range2 = 5..<10

        rangeStore.insert(value: "Value 1", range: range1)
        rangeStore.insert(value: "Value 2", range: range2)

        let searchResults = rangeStore.ranges(overlapping: 5..<6)
        XCTAssertEqual(searchResults.count, 1)
        XCTAssertEqual(searchResults[0].value, "Value 2")
    }

    func test_searchEmptyTree() {
        let rangeStore = RangeStore<String>()
        let searchResults = rangeStore.ranges(overlapping: 0..<5)
        XCTAssertTrue(searchResults.isEmpty)
    }

    func test_deleteNonExistentRange() {
        let rangeStore = RangeStore<String>()
        let range = 0..<5
        XCTAssertFalse(rangeStore.delete(range: range))
    }
}
