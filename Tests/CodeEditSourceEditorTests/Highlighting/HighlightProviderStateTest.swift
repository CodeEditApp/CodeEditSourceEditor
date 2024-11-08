import XCTest
import CodeEditTextView
import CodeEditLanguages
@testable import CodeEditSourceEditor

/// Because the provider state is mostly just passing messages between providers and the highlight state, what we need
/// to test is that invalidated ranges are sent to the delegate

class MockVisibleRangeProvider: VisibleRangeProvider {
    func setVisibleSet(_ newSet: IndexSet) {
        visibleSet = newSet
        delegate?.visibleSetDidUpdate(visibleSet)
    }
}

class EmptyHighlightProviderStateDelegate: HighlightProviderStateDelegate {
    func applyHighlightResult(
        provider: ProviderID,
        highlights: [HighlightRange],
        rangeToHighlight: NSRange
    ) { }
}

final class HighlightProviderStateTest: XCTestCase {
    @MainActor
    func test_setup() {
        let textView = Mock.textView()
        let rangeProvider = MockVisibleRangeProvider(textView: textView)
        let delegate = EmptyHighlightProviderStateDelegate()

        let setUpExpectation = XCTestExpectation(description: "Set up called.")

        let mockProvider = Mock.highlightProvider(
            onSetUp: { _ in
                setUpExpectation.fulfill()
            },
            onApplyEdit: { _, _, _ in .success(IndexSet()) },
            onQueryHighlightsFor: { _, _ in .success([]) }
        )

        _ = HighlightProviderState(
            id: 0,
            delegate: delegate,
            highlightProvider: mockProvider,
            textView: textView,
            visibleRangeProvider: rangeProvider,
            language: .swift
        )

        wait(for: [setUpExpectation], timeout: 1.0)
    }

    @MainActor
    func test_setLanguage() {
        let textView = Mock.textView()
        let rangeProvider = MockVisibleRangeProvider(textView: textView)
        let delegate = EmptyHighlightProviderStateDelegate()

        let firstSetUpExpectation = XCTestExpectation(description: "Set up called.")
        let secondSetUpExpectation = XCTestExpectation(description: "Set up called.")

        let mockProvider = Mock.highlightProvider(
            onSetUp: { language in
                switch language {
                case .c:
                    firstSetUpExpectation.fulfill()
                case .swift:
                    secondSetUpExpectation.fulfill()
                default:
                    XCTFail("Unexpected language: \(language)")
                }
            },
            onApplyEdit: { _, _, _ in .success(IndexSet()) },
            onQueryHighlightsFor: { _, _ in .success([]) }
        )

        let state = HighlightProviderState(
            id: 0,
            delegate: delegate,
            highlightProvider: mockProvider,
            textView: textView,
            visibleRangeProvider: rangeProvider,
            language: .c
        )

        wait(for: [firstSetUpExpectation], timeout: 1.0)

        state.setLanguage(language: .swift)

        wait(for: [secondSetUpExpectation], timeout: 1.0)
    }

    @MainActor
    func test_storageUpdatedRangesPassedOn() {
        let textView = Mock.textView()
        let rangeProvider = MockVisibleRangeProvider(textView: textView)
        let delegate = EmptyHighlightProviderStateDelegate()

        var updatedRanges: [(NSRange, Int)] = []

        let mockProvider = Mock.highlightProvider(
            onSetUp: { _ in },
            onApplyEdit: { _, range, delta in
                updatedRanges.append((range, delta))
                return .success(IndexSet())
            },
            onQueryHighlightsFor: { _, _ in .success([]) }
        )

        let state = HighlightProviderState(
            id: 0,
            delegate: delegate,
            highlightProvider: mockProvider,
            textView: textView,
            visibleRangeProvider: rangeProvider,
            language: .swift
        )

        let mockEdits: [(NSRange, Int)] = [
            (NSRange(location: 0, length: 10), 10), // Inserted 10
            (NSRange(location: 5, length: 0), -2), // Deleted 2 at 5
            (NSRange(location: 0, length: 2), 3), // Replaced 0-2 with 3
            (NSRange(location: 9, length: 1), 1),
            (NSRange(location: 0, length: 0), -10)
        ]

        for edit in mockEdits {
            state.storageDidUpdate(range: edit.0, delta: edit.1)
        }

        for (range, expected) in zip(updatedRanges, mockEdits) {
            XCTAssertEqual(range.0, expected.0)
            XCTAssertEqual(range.1, expected.1)
        }
    }
}
