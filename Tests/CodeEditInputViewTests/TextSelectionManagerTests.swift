import XCTest
@testable import CodeEditInputView

final class TextSelectionManagerTests: XCTestCase {
    var textStorage: NSTextStorage!
    var layoutManager: TextLayoutManager!

    override func setUp() {
        textStorage = NSTextStorage(string: "Loren Ipsum 💯")
        layoutManager = TextLayoutManager(
            textStorage: textStorage,
            typingAttributes: [:],
            lineHeightMultiplier: 1.0,
            wrapLines: false,
            textView: NSView(),
            delegate: nil
        )
    }

    func selectionManager() -> TextSelectionManager {
        TextSelectionManager(
            layoutManager: layoutManager,
            textStorage: textStorage,
            layoutView: nil,
            delegate: nil
        )
    }

    func test_updateSelectionLeft() {
        let selectionManager = selectionManager()
        let locations = [2, 0, 14, 14]
        let expectedRanges = [(1, 1), (0, 0), (12, 2), (13, 1)]
        let decomposeCharacters = [false, false, false, true]

        for idx in locations.indices {
            let range = selectionManager.rangeOfSelection(
                from: locations[idx],
                direction: .backward,
                destination: .character,
                decomposeCharacters: decomposeCharacters[idx]
            )

            XCTAssert(
                range.location == expectedRanges[idx].0,
                "Invalid Location. Testing location \(locations[idx]). Expected \(expectedRanges[idx]). Got \(range)"
            )
            XCTAssert(
                range.length == expectedRanges[idx].1,
                "Invalid Location. Testing location \(locations[idx]). Expected \(expectedRanges[idx]). Got \(range)"
            )
        }
    }

    func test_updateSelectionRight() {
        let selectionManager = selectionManager()
        let locations = [2, 0, 13, 12, 12]
        let expectedRanges = [(2, 1), (0, 1), (13, 0), (12, 2), (12, 1)]
        let decomposeCharacters = [false, false, false, false, true]

        for idx in locations.indices {
            let range = selectionManager.rangeOfSelection(
                from: locations[idx],
                direction: .forward,
                destination: .character,
                decomposeCharacters: decomposeCharacters[idx]
            )

            XCTAssert(
                range.location == expectedRanges[idx].0,
                "Invalid Location. Testing location \(locations[idx]). Expected \(expectedRanges[idx]). Got \(range)"
            )
            XCTAssert(
                range.length == expectedRanges[idx].1,
                "Invalid Location. Testing location \(locations[idx]). Expected \(expectedRanges[idx]). Got \(range)"
            )
        }
    }

    func test_updateSelectionLeftWord() {
        // TODO
    }

    func test_updateSelectionRightWord() {
        // TODO
    }

    func test_updateSelectionLeftLine() {
        // TODO
    }

    func test_updateSelectionRightLine() {
        // TODO
    }
}
