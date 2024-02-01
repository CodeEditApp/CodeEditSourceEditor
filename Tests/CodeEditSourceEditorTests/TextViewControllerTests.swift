import XCTest
@testable import CodeEditSourceEditor
import SwiftTreeSitter
import AppKit
import SwiftUI
import TextStory

// swiftlint:disable all
final class TextViewControllerTests: XCTestCase {

    var controller: TextViewController!
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
        controller = TextViewController(
            string: "",
            language: .default,
            font: .monospacedSystemFont(ofSize: 11, weight: .medium),
            theme: theme,
            tabWidth: 4,
            indentOption: .spaces(count: 4),
            lineHeight: 1.0,
            wrapLines: true,
            cursorPositions: [],
            editorOverscroll: 0.5,
            useThemeBackground: true,
            highlightProvider: nil,
            contentInsets: NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
            isEditable: true,
            isSelectable: true,
            letterSpacing: 1.0,
            bracketPairHighlight: .flash
        )

        controller.loadView()
    }

    // MARK: Capture Names

    func test_captureNames() throws {
        // test for "keyword"
        let captureName1 = "keyword"
        let color1 = controller.attributesFor(CaptureName(rawValue: captureName1))[.foregroundColor] as? NSColor
        XCTAssertEqual(color1, NSColor.systemPink)

        // test for "comment"
        let captureName2 = "comment"
        let color2 = controller.attributesFor(CaptureName(rawValue: captureName2))[.foregroundColor] as? NSColor
        XCTAssertEqual(color2, NSColor.systemGreen)

        /* ... additional tests here ... */

        // test for empty case
        let captureName3 = ""
        let color3 = controller.attributesFor(CaptureName(rawValue: captureName3))[.foregroundColor] as? NSColor
        XCTAssertEqual(color3, NSColor.textColor)

        // test for random case
        let captureName4 = "abc123"
        let color4 = controller.attributesFor(CaptureName(rawValue: captureName4))[.foregroundColor] as? NSColor
        XCTAssertEqual(color4, NSColor.textColor)
    }

    // MARK: Overscroll

    func test_editorOverScroll() throws {
        let scrollView = try XCTUnwrap(controller.view as? NSScrollView)
        scrollView.frame = .init(x: .zero,
                                 y: .zero,
                                 width: 100,
                                 height: 100)

        controller.editorOverscroll = 0
        controller.contentInsets = nil
        controller.reloadUI()

        // editorOverscroll: 0
        XCTAssertEqual(scrollView.contentView.contentInsets.bottom, 0)

        controller.editorOverscroll = 0.5
        controller.reloadUI()

        // editorOverscroll: 0.5
        XCTAssertEqual(scrollView.contentView.contentInsets.bottom, 50.0)

        controller.editorOverscroll = 1.0
        controller.reloadUI()

        // editorOverscroll: 1.0
        XCTAssertEqual(scrollView.contentView.contentInsets.bottom, 87.0)
    }

    // MARK: Insets

    func test_editorInsets() throws {
        let scrollView = try XCTUnwrap(controller.view as? NSScrollView)
        scrollView.frame = .init(x: .zero,
                                 y: .zero,
                                 width: 100,
                                 height: 100)

        func assertInsetsEqual(_ lhs: NSEdgeInsets, _ rhs: NSEdgeInsets) throws {
            XCTAssertEqual(lhs.top, rhs.top)
            XCTAssertEqual(lhs.right, rhs.right)
            XCTAssertEqual(lhs.bottom, rhs.bottom)
            XCTAssertEqual(lhs.left, rhs.left)
        }

        controller.editorOverscroll = 0
        controller.contentInsets = nil
        controller.reloadUI()

        // contentInsets: 0
        try assertInsetsEqual(scrollView.contentInsets, NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))

        // contentInsets: 16
        controller.contentInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        controller.reloadUI()

        try assertInsetsEqual(scrollView.contentInsets, NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))

        // contentInsets: different
        controller.contentInsets = NSEdgeInsets(top: 32.5, left: 12.3, bottom: 20, right: 1)
        controller.reloadUI()

        try assertInsetsEqual(scrollView.contentInsets, NSEdgeInsets(top: 32.5, left: 12.3, bottom: 20, right: 1))

        // contentInsets: 16
        // editorOverscroll: 0.5
        controller.contentInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        controller.editorOverscroll = 0.5
        controller.reloadUI()

        try assertInsetsEqual(scrollView.contentInsets, NSEdgeInsets(top: 16, left: 16, bottom: 16 + 50, right: 16))
    }

    func test_editorOverScroll_ZeroCondition() throws {
        let scrollView = try XCTUnwrap(controller.view as? NSScrollView)
        scrollView.frame = .zero

        // editorOverscroll: 0
        XCTAssertEqual(scrollView.contentView.contentInsets.bottom, 0)
    }

    // MARK: Indent

    func test_indentOptionString() {
        XCTAssertEqual(" ", IndentOption.spaces(count: 1).stringValue)
        XCTAssertEqual("  ", IndentOption.spaces(count: 2).stringValue)
        XCTAssertEqual("   ", IndentOption.spaces(count: 3).stringValue)
        XCTAssertEqual("    ", IndentOption.spaces(count: 4).stringValue)
        XCTAssertEqual("     ", IndentOption.spaces(count: 5).stringValue)

        XCTAssertEqual("\t", IndentOption.tab.stringValue)
    }

    func test_indentBehavior() {
        // Insert 1 space
        controller.indentOption = .spaces(count: 1)
        controller.textView.replaceCharacters(in: NSRange(location: 0, length: controller.textView.textStorage.length), with: "")
        controller.textView.selectionManager.setSelectedRange(NSRange(location: 0, length: 0))
        controller.textView.insertText("\t", replacementRange: .zero)
        XCTAssertEqual(controller.textView.string, " ")

        // Insert 2 spaces
        controller.indentOption = .spaces(count: 2)
        controller.textView.textStorage.replaceCharacters(in: NSRange(location: 0, length: controller.textView.textStorage.length), with: "")
        controller.textView.insertText("\t", replacementRange: .zero)
        XCTAssertEqual(controller.textView.string, "  ")

        // Insert 3 spaces
        controller.indentOption = .spaces(count: 3)
        controller.textView.replaceCharacters(in: NSRange(location: 0, length: controller.textView.textStorage.length), with: "")
        controller.textView.insertText("\t", replacementRange: .zero)
        XCTAssertEqual(controller.textView.string, "   ")

        // Insert 4 spaces
        controller.indentOption = .spaces(count: 4)
        controller.textView.replaceCharacters(in: NSRange(location: 0, length: controller.textView.textStorage.length), with: "")
        controller.textView.insertText("\t", replacementRange: .zero)
        XCTAssertEqual(controller.textView.string, "    ")

        // Insert tab
        controller.indentOption = .tab
        controller.textView.replaceCharacters(in: NSRange(location: 0, length: controller.textView.textStorage.length), with: "")
        controller.textView.insertText("\t", replacementRange: .zero)
        XCTAssertEqual(controller.textView.string, "\t")

        // Insert lots of spaces
        controller.indentOption = .spaces(count: 1000)
        print(controller.textView.textStorage.length)
        controller.textView.replaceCharacters(in: NSRange(location: 0, length: controller.textView.textStorage.length), with: "")
        controller.textView.insertText("\t", replacementRange: .zero)
        XCTAssertEqual(controller.textView.string, String(repeating: " ", count: 1000))
    }

    func test_letterSpacing() {
        let font: NSFont = .monospacedSystemFont(ofSize: 11, weight: .medium)

        controller.letterSpacing = 1.0

        XCTAssertEqual(
            controller.attributesFor(nil)[.kern]! as! CGFloat,
            (" " as NSString).size(withAttributes: [.font: font]).width * 0.0
        )

        controller.letterSpacing = 2.0
        XCTAssertEqual(
            controller.attributesFor(nil)[.kern]! as! CGFloat,
            (" " as NSString).size(withAttributes: [.font: font]).width * 1.0
        )

        controller.letterSpacing = 1.0
    }

    // MARK: Bracket Highlights

    func test_bracketHighlights() {
        controller.scrollView.setFrameSize(NSSize(width: 500, height: 500))
        controller.viewDidLoad()
        controller.bracketPairHighlight = nil
        controller.setText("{ Loren Ipsum {} }")
        controller.setCursorPositions([CursorPosition(line: 1, column: 2)]) // After first opening {
        XCTAssert(controller.highlightLayers.isEmpty, "Controller added highlight layer when setting is set to `nil`")
        controller.setCursorPositions([CursorPosition(line: 1, column: 3)])

        controller.bracketPairHighlight = .bordered(color: .black)
        controller.textView.setNeedsDisplay()
        controller.setCursorPositions([CursorPosition(line: 1, column: 2)]) // After first opening {
        XCTAssert(controller.highlightLayers.count == 2, "Controller created an incorrect number of layers for bordered. Expected 2, found \(controller.highlightLayers.count)")
        controller.setCursorPositions([CursorPosition(line: 1, column: 3)])
        XCTAssert(controller.highlightLayers.isEmpty, "Controller failed to remove bracket pair layers.")

        controller.bracketPairHighlight = .underline(color: .black)
        controller.setCursorPositions([CursorPosition(line: 1, column: 2)]) // After first opening {
        XCTAssert(controller.highlightLayers.count == 2, "Controller created an incorrect number of layers for underline. Expected 2, found \(controller.highlightLayers.count)")
        controller.setCursorPositions([CursorPosition(line: 1, column: 3)])
        XCTAssert(controller.highlightLayers.isEmpty, "Controller failed to remove bracket pair layers.")

        controller.bracketPairHighlight = .flash
        controller.setCursorPositions([CursorPosition(line: 1, column: 2)]) // After first opening {
        XCTAssert(controller.highlightLayers.count == 1, "Controller created more than one layer for flash animation. Expected 1, found \(controller.highlightLayers.count)")
        controller.setCursorPositions([CursorPosition(line: 1, column: 3)])
        XCTAssert(controller.highlightLayers.isEmpty, "Controller failed to remove bracket pair layers.")

        controller.setCursorPositions([CursorPosition(line: 1, column: 2)]) // After first opening {
        XCTAssert(controller.highlightLayers.count == 1, "Controller created more than one layer for flash animation. Expected 1, found \(controller.highlightLayers.count)")
        let exp = expectation(description: "Test after 0.8 seconds")
        let result = XCTWaiter.wait(for: [exp], timeout: 0.8)
        if result == XCTWaiter.Result.timedOut {
            XCTAssert(controller.highlightLayers.isEmpty, "Controller failed to remove layer after flash animation. Expected 0, found \(controller.highlightLayers.count)")
        } else {
            XCTFail("Delay interrupted")
        }
    }

    func test_findClosingPair() {
        controller.textView.string = "{ Loren Ipsum {} }"
        var idx: Int?

        // Test walking forwards
        idx = controller.findClosingPair("{", "}", from: 1, limit: 18, reverse: false)
        XCTAssert(idx == 17, "Walking forwards failed. Expected `17`, found: `\(String(describing: idx))`")

        // Test walking backwards
        idx = controller.findClosingPair("}", "{", from: 17, limit: 0, reverse: true)
        XCTAssert(idx == 0, "Walking backwards failed. Expected `0`, found: `\(String(describing: idx))`")

        // Test extra pair
        controller.textView.string = "{ Loren Ipsum {}} }"
        idx = controller.findClosingPair("{", "}", from: 1, limit: 19, reverse: false)
        XCTAssert(idx == 16, "Walking forwards with extra bracket pair failed. Expected `16`, found: `\(String(describing: idx))`")

        // Text extra pair backwards
        controller.textView.string = "{ Loren Ipsum {{} }"
        idx = controller.findClosingPair("}", "{", from: 18, limit: 0, reverse: true)
        XCTAssert(idx == 14, "Walking backwards with extra bracket pair failed. Expected `14`, found: `\(String(describing: idx))`")

        // Test missing pair
        controller.textView.string = "{ Loren Ipsum { }"
        idx = controller.findClosingPair("{", "}", from: 1, limit: 17, reverse: false)
        XCTAssert(idx == nil, "Walking forwards with missing pair failed. Expected `nil`, found: `\(String(describing: idx))`")

        // Test missing pair backwards
        controller.textView.string = " Loren Ipsum {} }"
        idx = controller.findClosingPair("}", "{", from: 17, limit: 0, reverse: true)
        XCTAssert(idx == nil, "Walking backwards with missing pair failed. Expected `nil`, found: `\(String(describing: idx))`")
    }

    // MARK: Set Text

    func test_setText() {
        controller.textView.string = "Hello World"
        controller.textView.selectionManager.setSelectedRange(NSRange(location: 1, length: 2))

        controller.setText("\nHello World with newline!")

        XCTAssert(controller.string == "\nHello World with newline!")
        XCTAssertEqual(controller.cursorPositions.count, 1)
        XCTAssertEqual(controller.cursorPositions[0].line, 2)
        XCTAssertEqual(controller.cursorPositions[0].column, 1)
        XCTAssertEqual(controller.cursorPositions[0].range.location, 1)
        XCTAssertEqual(controller.cursorPositions[0].range.length, 2)
        XCTAssertEqual(controller.textView.selectionManager.textSelections.count, 1)
        XCTAssertEqual(controller.textView.selectionManager.textSelections[0].range.location, 1)
        XCTAssertEqual(controller.textView.selectionManager.textSelections[0].range.length, 2)
    }

    // MARK: Cursor Positions

    func test_cursorPositionRangeInit() {
        controller.setText("Hello World")

        // Test adding a position returns a valid one
        controller.setCursorPositions([CursorPosition(range: NSRange(location: 0, length: 5))])
        XCTAssertEqual(controller.cursorPositions.count, 1)
        XCTAssertEqual(controller.cursorPositions[0].range.location, 0)
        XCTAssertEqual(controller.cursorPositions[0].range.length, 5)
        XCTAssertEqual(controller.cursorPositions[0].line, 1)
        XCTAssertEqual(controller.cursorPositions[0].column, 1)

        // Test an invalid position is ignored
        controller.setCursorPositions([CursorPosition(range: NSRange(location: -1, length: 25))])
        XCTAssertTrue(controller.cursorPositions.count == 0)

        // Test that column and line are correct
        controller.setText("1\n2\n3\n4\n")
        controller.setCursorPositions([CursorPosition(range: NSRange(location: 2, length: 0))])
        XCTAssertEqual(controller.cursorPositions.count, 1)
        XCTAssertEqual(controller.cursorPositions[0].range.location, 2)
        XCTAssertEqual(controller.cursorPositions[0].range.length, 0)
        XCTAssertEqual(controller.cursorPositions[0].line, 2)
        XCTAssertEqual(controller.cursorPositions[0].column, 1)

        // Test order and validity of multiple positions.
        controller.setCursorPositions([
            CursorPosition(range: NSRange(location: 2, length: 0)),
            CursorPosition(range: NSRange(location: 5, length: 1))
        ])
        XCTAssertEqual(controller.cursorPositions.count, 2)
        XCTAssertEqual(controller.cursorPositions[0].range.location, 2)
        XCTAssertEqual(controller.cursorPositions[0].range.length, 0)
        XCTAssertEqual(controller.cursorPositions[0].line, 2)
        XCTAssertEqual(controller.cursorPositions[0].column, 1)
        XCTAssertEqual(controller.cursorPositions[1].range.location, 5)
        XCTAssertEqual(controller.cursorPositions[1].range.length, 1)
        XCTAssertEqual(controller.cursorPositions[1].line, 3)
        XCTAssertEqual(controller.cursorPositions[1].column, 2)
    }

    func test_cursorPositionRowColInit() {
        controller.setText("Hello World")

        // Test adding a position returns a valid one
        controller.setCursorPositions([CursorPosition(line: 1, column: 1)])
        XCTAssertEqual(controller.cursorPositions.count, 1)
        XCTAssertEqual(controller.cursorPositions[0].range.location, 0)
        XCTAssertEqual(controller.cursorPositions[0].range.length, 0)
        XCTAssertEqual(controller.cursorPositions[0].line, 1)
        XCTAssertEqual(controller.cursorPositions[0].column, 1)

        // Test an invalid position is ignored
        controller.setCursorPositions([CursorPosition(line: -1, column: 10)])
        XCTAssertTrue(controller.cursorPositions.count == 0)

        // Test that column and line are correct
        controller.setText("1\n2\n3\n4\n")
        controller.setCursorPositions([CursorPosition(line: 2, column: 1)])
        XCTAssertEqual(controller.cursorPositions.count, 1)
        XCTAssertEqual(controller.cursorPositions[0].range.location, 2)
        XCTAssertEqual(controller.cursorPositions[0].range.length, 0)
        XCTAssertEqual(controller.cursorPositions[0].line, 2)
        XCTAssertEqual(controller.cursorPositions[0].column, 1)

        // Test order and validity of multiple positions.
        controller.setCursorPositions([
            CursorPosition(line: 1, column: 1),
            CursorPosition(line: 3, column: 1)
        ])
        XCTAssertEqual(controller.cursorPositions.count, 2)
        XCTAssertEqual(controller.cursorPositions[0].range.location, 0)
        XCTAssertEqual(controller.cursorPositions[0].range.length, 0)
        XCTAssertEqual(controller.cursorPositions[0].line, 1)
        XCTAssertEqual(controller.cursorPositions[0].column, 1)
        XCTAssertEqual(controller.cursorPositions[1].range.location, 4)
        XCTAssertEqual(controller.cursorPositions[1].range.length, 0)
        XCTAssertEqual(controller.cursorPositions[1].line, 3)
        XCTAssertEqual(controller.cursorPositions[1].column, 1)
    }
}
// swiftlint:enable all
