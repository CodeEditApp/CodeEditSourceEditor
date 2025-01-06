import XCTest
import CodeEditTextView
import CodeEditLanguages
@testable import CodeEditSourceEditor

final class HighlighterTests: XCTestCase {
    class MockHighlightProvider: HighlightProviding {
        var didQueryFirst = false
        var didQueryAgain = false

        func setUp(textView: TextView, codeLanguage: CodeLanguage) { }

        func applyEdit(
            textView: TextView,
            range: NSRange,
            delta: Int,
            completion: @escaping @MainActor (Result<IndexSet, Error>) -> Void
        ) {
            completion(.success(.init(integersIn: NSRange(location: 0, length: 10))))
        }

        func queryHighlightsFor(
            textView: TextView,
            range: NSRange,
            completion: @escaping @MainActor (Result<[HighlightRange], Error>) -> Void
        ) {
            if !didQueryFirst {
                didQueryFirst = true
                completion(.failure(HighlightProvidingError.operationCancelled))
            } else {
                didQueryAgain = true
                completion(.success([]))
            }
        }
    }

    class MockAttributeProvider: ThemeAttributesProviding {
        func attributesFor(_ capture: CaptureName?) -> [NSAttributedString.Key: Any] { [:] }
    }

    class SentryStorageDelegate: NSObject, NSTextStorageDelegate {
        var editedIndices: IndexSet = IndexSet()

        func textStorage(
            _ textStorage: NSTextStorage,
            didProcessEditing editedMask: NSTextStorageEditActions,
            range editedRange: NSRange,
            changeInLength delta: Int) {
                editedIndices.insert(integersIn: editedRange)
            }
    }

    var attributeProvider: MockAttributeProvider!
    var textView: TextView!

    override func setUp() {
        attributeProvider = MockAttributeProvider()
        textView = Mock.textView()
        textView.frame = NSRect(x: 0, y: 0, width: 1000, height: 1000)
    }

    @MainActor
    func test_canceledHighlightsAreInvalidated() {
        let highlightProvider = MockHighlightProvider()
        textView.setText("Hello World!")
        let highlighter = Mock.highlighter(
            textView: textView,
            highlightProvider: highlightProvider,
            attributeProvider: attributeProvider
        )

        highlighter.invalidate()

        XCTAssertTrue(highlightProvider.didQueryFirst, "Highlighter did not invalidate text.")
        XCTAssertTrue(
            highlightProvider.didQueryAgain,
            "Highlighter did not query again after cancelling the first request"
        )
    }

    @MainActor
    func test_highlightsDoNotInvalidateEntireTextView() {
        let highlightProvider = TreeSitterClient()
        highlightProvider.forceSyncOperation = true
        textView.setText("func helloWorld() {\n\tprint(\"Hello World!\")\n}")

        let highlighter = Mock.highlighter(
            textView: textView,
            highlightProvider: highlightProvider,
            attributeProvider: attributeProvider
        )

        highlighter.invalidate()

        let sentryStorage = SentryStorageDelegate()
        textView.addStorageDelegate(sentryStorage)

        let invalidSet = IndexSet(integersIn: NSRange(location: 0, length: 24))
        highlighter.invalidate(invalidSet) // Invalidate first line

        XCTAssertEqual(sentryStorage.editedIndices, invalidSet) // Should only cause highlights on the first line
    }

    // This test isn't testing much highlighter functionality. However, we've seen crashes and other errors after normal
    // editing that were caused by the highlighter and would only have been caught by an integration test like this.
    @MainActor
    func test_editFile() {
        let highlightProvider = TreeSitterClient()
        highlightProvider.forceSyncOperation = true
        textView.setText("func helloWorld() {\n\tprint(\"Hello World!\")\n}") // 44 chars

        let highlighter = Mock.highlighter(
            textView: textView,
            highlightProvider: highlightProvider,
            attributeProvider: attributeProvider
        )
        textView.addStorageDelegate(highlighter)
        highlighter.setLanguage(language: .swift)
        highlighter.invalidate()

        // Delete Characters
        textView.replaceCharacters(in: [NSRange(location: 43, length: 1)], with: "")
        textView.replaceCharacters(in: [NSRange(location: 0, length: 4)], with: "")
        textView.replaceCharacters(in: [NSRange(location: 6, length: 5)], with: "")
        textView.replaceCharacters(in: [NSRange(location: 25, length: 5)], with: "")

        XCTAssertEqual(textView.string, " hello() {\n\tprint(\"Hello !\")\n")

        // Insert Characters
        textView.replaceCharacters(in: [NSRange(location: 29, length: 0)], with: "}")
        textView.replaceCharacters(
            in: [NSRange(location: 25, length: 0), NSRange(location: 6, length: 0)],
            with: "World"
        )
        // emulate typing with a cursor
        textView.selectionManager.setSelectedRange(NSRange(location: 0, length: 0))
        textView.insertText("f")
        textView.insertText("u")
        textView.insertText("n")
        textView.insertText("c")
        XCTAssertEqual(textView.string, "func helloWorld() {\n\tprint(\"Hello World!\")\n}")

        // Replace contents
        textView.replaceCharacters(in: textView.documentRange, with: "")
        textView.insertText("func helloWorld() {\n\tprint(\"Hello World!\")\n}")
        XCTAssertEqual(textView.string, "func helloWorld() {\n\tprint(\"Hello World!\")\n}")
    }
}
