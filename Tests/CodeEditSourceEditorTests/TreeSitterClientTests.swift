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

    func test_clientSetup() async {
        await client.setUp(textView: textView, codeLanguage: .swift)
        
        let primaryLanguage = await client.state?.primaryLayer.id
        let layerCount = await client.state?.layers.count
        XCTAssert(primaryLanguage == .swift, "Client set up incorrect language")
        XCTAssert(layerCount == 1, "Client set up too many layers")
    }
}
// swiftlint:enable all
