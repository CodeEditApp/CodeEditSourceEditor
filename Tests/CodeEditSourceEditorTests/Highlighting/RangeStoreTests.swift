import XCTest
@testable import CodeEditSourceEditor

class RangeStoreTests: XCTestCase {
    var rangeStore: RangeStore<String>!

    override func setUp() {
        super.setUp()
        rangeStore = RangeStore<String>()
    }

    func test_insertRange() {
        let range1 = 0..<5
        let range2 = 5..<10
        let range3 = 10..<15

        rangeStore.insert(value: "Value 1", range: range1)
        rangeStore.insert(value: "Value 2", range: range2)
        rangeStore.insert(value: "Value 3", range: range3)

        // Validate that the inserted ranges are present
        let results = rangeStore.ranges(overlapping: 0..<20)
        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(results[0].value, "Value 1")
        XCTAssertEqual(results[1].value, "Value 2")
        XCTAssertEqual(results[2].value, "Value 3")
    }

    func test_deleteRange() {
        let range1 = 0..<5
        let range2 = 5..<10

        rangeStore.insert(value: "Value 1", range: range1)
        rangeStore.insert(value: "Value 2", range: range2)

        // Delete range2
        XCTAssertTrue(rangeStore.delete(range: range2))

        // Validate that range2 is deleted
        let resultsAfterDelete = rangeStore.ranges(overlapping: 0..<20)
        XCTAssertEqual(resultsAfterDelete.count, 1)
        XCTAssertEqual(resultsAfterDelete[0].value, "Value 1")
    }

    func test_searchRange() {
        let range1 = 0..<5
        let range2 = 5..<10

        rangeStore.insert(value: "Value 1", range: range1)
        rangeStore.insert(value: "Value 2", range: range2)

        // Search for a specific range
        let searchResults = rangeStore.ranges(overlapping: 5..<6)
        XCTAssertEqual(searchResults.count, 1)
        XCTAssertEqual(searchResults[0].value, "Value 2")
    }

    func test_searchEmptyTree() {
        // Search in an empty tree
        let searchResults = rangeStore.ranges(overlapping: 0..<5)
        XCTAssertTrue(searchResults.isEmpty)
    }

    func test_deleteNonExistentRange() {
        let range = 0..<5
        // Attempt to delete a range that doesn't exist
        XCTAssertFalse(rangeStore.delete(range: range))
    }
}
