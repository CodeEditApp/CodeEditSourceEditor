import XCTest
@testable import CodeEditTextView

fileprivate class TestTextView: HighlighterTextView {
    var testString: NSMutableString = "func testSwiftFunc() -> Int {\n\tprint(\"\")\n}"

    var documentRange: NSRange {
        NSRange(location: 0, length: testString.length)
    }

    func stringForRange(_ nsRange: NSRange) -> String? {
        testString.substring(with: nsRange)
    }
}

// swiftlint:disable all
final class TreeSitterClientTests: XCTestCase {

    fileprivate var textView = TestTextView()
    var client: TreeSitterClient!

    override func setUp() {
        client = TreeSitterClient { nsRange, _ in
            self.textView.stringForRange(nsRange)
        }
    }

    func test_clientSetup() {
        client.setUp(textView: textView, codeLanguage: .swift)
        XCTAssert(client.hasOutstandingWork, "Client should queue language loading on a background task.")

        let editExpectation = expectation(description: "Edit work should never return")
        editExpectation.isInverted = true // Expect to never happen

        textView.testString.insert("let int = 0\n", at: 0)
        client.applyEdit(textView: textView, range: NSRange(location: 0, length: 12), delta: 12) { _ in
            editExpectation.fulfill()
        }

        client.setUp(textView: textView, codeLanguage: .swift)
        XCTAssert(client.hasOutstandingWork, "Client should queue language loading on a background task.")
        XCTAssert(client.queuedEdits.count == 1, "Client should cancel all queued work when setUp is called.")

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    // Test async language loading with edits and highlights queued before loading completes.
    func test_languageLoad() {
        textView = TestTextView()
        client.setUp(textView: textView, codeLanguage: .swift)

        XCTAssert(client.hasOutstandingWork, "Client should queue language loading on a background task.")

        let editExpectation = expectation(description: "Edit work should return first.")
        let highlightExpectation = expectation(description: "Highlight should return last.")

        client.queryHighlightsFor(textView: textView, range: NSRange(location: 0, length: 42)) { _ in
            highlightExpectation.fulfill()
        }

        textView.testString.insert("let int = 0\n", at: 0)
        client.applyEdit(textView: textView, range: NSRange(location: 0, length: 12), delta: 12) { _ in
            editExpectation.fulfill()
        }

        wait(for: [editExpectation, highlightExpectation], timeout: 10.0, enforceOrder: true)
    }

    // Edits should be consumed before highlights.
    func test_queueOrder() {
        textView = TestTextView()
        client.setUp(textView: textView, codeLanguage: .swift)

        let editExpectation = expectation(description: "Edit work should return first.")
        let editExpectation2 = expectation(description: "Edit2 should return 2nd.")
        let highlightExpectation = expectation(description: "Highlight should return 3rd.")

        // Do initial query while language loads.
        client.queryHighlightsFor(textView: textView, range: NSRange(location: 0, length: 42)) { _ in
            print("highlightExpectation")
            highlightExpectation.fulfill()
        }

        // Queue another edit
        textView.testString.insert("let int = 0\n", at: 0)
        client.applyEdit(textView: textView, range: NSRange(location: 0, length: 12), delta: 12) { _ in
            print("editExpectation")
            editExpectation.fulfill()
        }

        // One more edit
        textView.testString.insert("let int = 0\n", at: 0)
        client.applyEdit(textView: textView, range: NSRange(location: 0, length: 12), delta: 12) { _ in
            print("editExpectation2")
            editExpectation2.fulfill()
        }

        wait(
            for: [
                editExpectation,
                editExpectation2,
                highlightExpectation,
            ],
            timeout: 10.0,
            enforceOrder: true
        )
    }
}
// swiftlint:enable all
