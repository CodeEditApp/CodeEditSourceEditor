import XCTest
import CodeEditTextView
@testable import CodeEditSourceEditor

// swiftlint:disable all

final class TreeSitterClientTests: XCTestCase {

    class Delegate: TextViewDelegate { }

    fileprivate var textView = TextView(
        string: "func testSwiftFunc() -> Int {\n\tprint(\"\")\n}",
        font: .monospacedSystemFont(ofSize: 12, weight: .regular),
        textColor: .labelColor,
        lineHeightMultiplier: 1.0,
        wrapLines: true,
        isEditable: true,
        isSelectable: true,
        letterSpacing: 1.0,
        delegate: Delegate()
    )
    var client: TreeSitterClient!

    override func setUp() {
        client = TreeSitterClient()
    }

    func test_clientSetup() {
        client.setUp(textView: textView, codeLanguage: .swift)

        let now = Date()
        while client.state == nil && abs(now.timeIntervalSinceNow) < 5 {
            usleep(1000)
        }

        if abs(now.timeIntervalSinceNow) >= 5 {
            XCTFail("Client took more than 5 seconds to set up.")
        }

        let primaryLanguage = client.state?.primaryLayer.id
        let layerCount = client.state?.layers.count
        XCTAssertEqual(primaryLanguage, .swift, "Client set up incorrect language")
        XCTAssertEqual(layerCount, 1, "Client set up too many layers")
    }
}
// swiftlint:enable all
