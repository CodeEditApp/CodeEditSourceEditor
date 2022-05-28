import XCTest
@testable import CodeEditTextView
@testable import CodeLanguage

final class CodeEditTextViewTests: XCTestCase {

    func test_LineHeight() throws {
        let font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        XCTAssertEqual(12, font.lineHeight)
    }

}
