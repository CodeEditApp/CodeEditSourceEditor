import XCTest
@testable import CodeEditSourceEditor

extension StyledRangeStore {
    var length: Int { _guts.summary.length }
    var count: Int { _guts.count }
}

final class StyledRangeStoreTests: XCTestCase {
    override var continueAfterFailure: Bool {
        get { false }
        set { }
    }

    func test_initWithLength() {
        for _ in 0..<100 {
            let length = Int.random(in: 0..<1000)
            let store = StyledRangeStore(documentLength: length)
            XCTAssertEqual(store.length, length)
        }
    }

    // MARK: - Storage

    func test_storageRemoveCharacters() {
        let store = StyledRangeStore(documentLength: 100)
        store.storageUpdated(replacedCharactersIn: 10..<12, withCount: 0)
        XCTAssertEqual(store.length, 98, "Failed to remove correct range")
        XCTAssertEqual(store.count, 1, "Failed to coalesce")
    }

    func test_storageRemoveFromEnd() {
        let store = StyledRangeStore(documentLength: 100)
        store.storageUpdated(replacedCharactersIn: 95..<100, withCount: 0)
        XCTAssertEqual(store.length, 95, "Failed to remove correct range")
        XCTAssertEqual(store.count, 1, "Failed to coalesce")
    }

    func test_storageRemoveSingleCharacterFromEnd() {
        let store = StyledRangeStore(documentLength: 10)
        store.set( // Test that we can delete a character associated with a single syntax run too
            runs: [
                .empty(length: 8),
                .init(length: 1, modifiers: [.abstract]),
                .init(length: 1, modifiers: [.declaration])],
            for: 0..<10
        )
        store.storageUpdated(replacedCharactersIn: 9..<10, withCount: 0)
        XCTAssertEqual(store.length, 9, "Failed to remove correct range")
        XCTAssertEqual(store.count, 2)
    }

    func test_storageRemoveFromBeginning() {
        let store = StyledRangeStore(documentLength: 100)
        store.storageUpdated(replacedCharactersIn: 0..<15, withCount: 0)
        XCTAssertEqual(store.length, 85, "Failed to remove correct range")
        XCTAssertEqual(store.count, 1, "Failed to coalesce")
    }

    func test_storageRemoveAll() {
        let store = StyledRangeStore(documentLength: 100)
        store.storageUpdated(replacedCharactersIn: 0..<100, withCount: 0)
        XCTAssertEqual(store.length, 0, "Failed to remove correct range")
        XCTAssertEqual(store.count, 0, "Failed to remove all runs")
    }

    func test_storageInsert() {
        let store = StyledRangeStore(documentLength: 100)
        store.storageUpdated(replacedCharactersIn: 45..<45, withCount: 10)
        XCTAssertEqual(store.length, 110)
        XCTAssertEqual(store.count, 1, "Failed to coalesce")
    }

    func test_storageInsertAtEnd() {
        let store = StyledRangeStore(documentLength: 100)
        store.storageUpdated(replacedCharactersIn: 100..<100, withCount: 10)
        XCTAssertEqual(store.length, 110)
        XCTAssertEqual(store.count, 1, "Failed to coalesce")
    }

    func test_storageInsertAtBeginning() {
        let store = StyledRangeStore(documentLength: 100)
        store.storageUpdated(replacedCharactersIn: 0..<0, withCount: 10)
        XCTAssertEqual(store.length, 110)
        XCTAssertEqual(store.count, 1, "Failed to coalesce")
    }

    func test_storageInsertFromEmpty() {
        let store = StyledRangeStore(documentLength: 0)
        store.storageUpdated(replacedCharactersIn: 0..<0, withCount: 10)
        XCTAssertEqual(store.length, 10)
        XCTAssertEqual(store.count, 1, "Failed to coalesce")
    }

    func test_storageEdit() {
        let store = StyledRangeStore(documentLength: 100)
        store.storageUpdated(replacedCharactersIn: 45..<50, withCount: 10)
        XCTAssertEqual(store.length, 105)
        XCTAssertEqual(store.count, 1, "Failed to coalesce")
    }

    func test_storageEditAtEnd() {
        let store = StyledRangeStore(documentLength: 100)
        store.storageUpdated(replacedCharactersIn: 95..<100, withCount: 10)
        XCTAssertEqual(store.length, 105)
        XCTAssertEqual(store.count, 1, "Failed to coalesce")
    }

    func test_storageEditAtBeginning() {
        let store = StyledRangeStore(documentLength: 100)
        store.storageUpdated(replacedCharactersIn: 0..<5, withCount: 10)
        XCTAssertEqual(store.length, 105)
        XCTAssertEqual(store.count, 1, "Failed to coalesce")
    }

    func test_storageEditAll() {
        let store = StyledRangeStore(documentLength: 100)
        store.storageUpdated(replacedCharactersIn: 0..<100, withCount: 10)
        XCTAssertEqual(store.length, 10)
        XCTAssertEqual(store.count, 1, "Failed to coalesce")
    }

    // MARK: - Styles

    func test_setOneRun() {
        let store = StyledRangeStore(documentLength: 100)
        store.set(capture: .comment, modifiers: [.static], for: 45..<50)
        XCTAssertEqual(store.length, 100)
        XCTAssertEqual(store.count, 3)

        let runs = store.runs(in: 0..<100)
        XCTAssertEqual(runs.count, 3)
        XCTAssertEqual(runs[0].length, 45)
        XCTAssertEqual(runs[1].length, 5)
        XCTAssertEqual(runs[2].length, 50)

        XCTAssertNil(runs[0].capture)
        XCTAssertEqual(runs[1].capture, .comment)
        XCTAssertNil(runs[2].capture)

        XCTAssertEqual(runs[0].modifiers, [])
        XCTAssertEqual(runs[1].modifiers, [.static])
        XCTAssertEqual(runs[2].modifiers, [])
    }

    func test_queryOverlappingRun() {
        let store = StyledRangeStore(documentLength: 100)
        store.set(capture: .comment, modifiers: [.static], for: 45..<50)
        XCTAssertEqual(store.length, 100)
        XCTAssertEqual(store.count, 3)

        let runs = store.runs(in: 47..<100)
        XCTAssertEqual(runs.count, 2)
        XCTAssertEqual(runs[0].length, 3)
        XCTAssertEqual(runs[1].length, 50)

        XCTAssertEqual(runs[0].capture, .comment)
        XCTAssertNil(runs[1].capture)

        XCTAssertEqual(runs[0].modifiers, [.static])
        XCTAssertEqual(runs[1].modifiers, [])
    }

    func test_setMultipleRuns() {
        let store = StyledRangeStore(documentLength: 100)

        store.set(capture: .comment, modifiers: [.static], for: 5..<15)
        store.set(capture: .keyword, modifiers: [], for: 20..<30)
        store.set(capture: .string, modifiers: [.static], for: 35..<40)
        store.set(capture: .function, modifiers: [], for: 45..<50)
        store.set(capture: .variable, modifiers: [], for: 60..<70)

        XCTAssertEqual(store.length, 100)

        let runs = store.runs(in: 0..<100)
        XCTAssertEqual(runs.count, 11)
        XCTAssertEqual(runs.reduce(0, { $0 + $1.length }), 100)

        let lengths = [5, 10, 5, 10, 5, 5, 5, 5, 10, 10, 30]
        let captures: [CaptureName?] = [nil, .comment, nil, .keyword, nil, .string, nil, .function, nil, .variable, nil]
        let modifiers: [CaptureModifierSet] = [[], [.static], [], [], [], [.static], [], [], [], [], []]

        runs.enumerated().forEach {
            XCTAssertEqual($0.element.length, lengths[$0.offset])
            XCTAssertEqual($0.element.capture, captures[$0.offset])
            XCTAssertEqual($0.element.modifiers, modifiers[$0.offset])
        }
    }

    func test_setMultipleRunsAndStorageUpdate() {
        let store = StyledRangeStore(documentLength: 100)

        var lengths = [5, 10, 5, 10, 5, 5, 5, 5, 10, 10, 30]
        var captures: [CaptureName?] = [nil, .comment, nil, .keyword, nil, .string, nil, .function, nil, .variable, nil]
        var modifiers: [CaptureModifierSet] = [[], [.static], [], [], [], [.static], [], [], [], [], []]

        store.set(
            runs: zip(zip(lengths, captures), modifiers).map {
                StyledRangeStore.Run(length: $0.0, capture: $0.1, modifiers: $1)
            },
            for: 0..<100
        )

        XCTAssertEqual(store.length, 100)

        var runs = store.runs(in: 0..<100)
        XCTAssertEqual(runs.count, 11)
        XCTAssertEqual(runs.reduce(0, { $0 + $1.length }), 100)

        runs.enumerated().forEach {
            XCTAssertEqual(
                $0.element.length,
                lengths[$0.offset],
                "Run \($0.offset) has incorrect length: \($0.element.length). Expected \(lengths[$0.offset])"
            )
            XCTAssertEqual(
                $0.element.capture,
                captures[$0.offset], // swiftlint:disable:next line_length
                "Run \($0.offset) has incorrect capture: \(String(describing: $0.element.capture)). Expected \(String(describing: captures[$0.offset]))"
            )
            XCTAssertEqual(
                $0.element.modifiers,
                modifiers[$0.offset],
                "Run \($0.offset) has incorrect modifiers: \($0.element.modifiers). Expected \(modifiers[$0.offset])"
            )
        }

        store.storageUpdated(replacedCharactersIn: 30..<45, withCount: 10)
        runs = store.runs(in: 0..<95)
        XCTAssertEqual(runs.count, 9)
        XCTAssertEqual(runs.reduce(0, { $0 + $1.length }), 95)

        lengths = [5, 10, 5, 10, 10, 5, 10, 10, 30]
        captures = [nil, .comment, nil, .keyword, nil, .function, nil, .variable, nil]
        modifiers = [[], [.static], [], [], [], [], [], [], []]

        runs.enumerated().forEach {
            XCTAssertEqual($0.element.length, lengths[$0.offset])
            XCTAssertEqual($0.element.capture, captures[$0.offset])
            XCTAssertEqual($0.element.modifiers, modifiers[$0.offset])
        }
    }
}
