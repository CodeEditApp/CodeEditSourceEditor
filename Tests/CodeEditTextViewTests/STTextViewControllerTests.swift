import XCTest
@testable import CodeEditTextView
import SwiftTreeSitter

final class STTextViewControllerTests: XCTestCase {

    var controller: STTextViewController!
    var theme: EditorTheme!

    override func setUpWithError() throws {
        theme = EditorTheme(
            text: .textColor,
            insertionPoint: .textColor,
            invisibles: .gray,
            background: .textBackgroundColor,
            lineHighlight: .highlightColor,
            selection: .selectedTextColor,
            keywords: .systemPink,
            commands: .systemBlue,
            types: .systemMint,
            attributes: .systemTeal,
            variables: .systemCyan,
            values: .systemOrange,
            numbers: .systemYellow,
            strings: .systemRed,
            characters: .systemRed,
            comments: .systemGreen
        )
        controller = STTextViewController(
            text: .constant(""),
            language: .default,
            font: .monospacedSystemFont(ofSize: 11, weight: .medium),
            theme: theme,
            tabWidth: 4
        )
    }

    func test_captureNames() throws {
        // test for "keyword"
        let captureName1 = "keyword"
        let color1 = controller.colorForCapture(captureName1)
        XCTAssertEqual(color1, .systemPink)

        // test for "comment"
        let captureName2 = "comment"
        let color2 = controller.colorForCapture(captureName2)
        XCTAssertEqual(color2, .systemGreen)

        /* ... additional tests here ... */

        // test for empty case
        let captureName3 = ""
        let color3 = controller.colorForCapture(captureName3)
        XCTAssertEqual(color3, .textColor)

        // test for random case
        let captureName4 = "abc123"
        let color4 = controller.colorForCapture(captureName4)
        XCTAssertEqual(color4, .textColor)
    }

}
