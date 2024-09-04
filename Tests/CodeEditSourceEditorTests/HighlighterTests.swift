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

    @MainActor
    func test_canceledHighlightsAreInvalidated() {
        let highlightProvider = MockHighlightProvider()
        let attributeProvider = MockAttributeProvider()
        let theme = Mock.theme()
        let textView = Mock.textView()
        textView.frame = NSRect(x: 0, y: 0, width: 1000, height: 1000)
        textView.setText("Hello World!")
        let highlighter = Mock.highlighter(
            textView: textView,
            highlightProvider: highlightProvider,
            theme: theme,
            attributeProvider: attributeProvider
        )

        highlighter.invalidate()

        XCTAssertTrue(highlightProvider.didQueryFirst, "Highlighter did not invalidate text.")
        XCTAssertTrue(
            highlightProvider.didQueryAgain,
            "Highlighter did not query again after cancelling the first request"
        )
    }
}
