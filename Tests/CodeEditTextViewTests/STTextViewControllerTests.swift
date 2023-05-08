import XCTest
@testable import CodeEditTextView
import SwiftTreeSitter
import AppKit
import TextStory

// swiftlint:disable all
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
            tabWidth: 4,
            indentOption: .spaces(count: 4),
            lineHeight: 1.0,
            wrapLines: true,
            cursorPosition: .constant((1, 1)),
            editorOverscroll: 0.5,
            useThemeBackground: true,
            isEditable: true,
            letterSpacing: 1.0
        )

        controller.loadView()
    }

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
        controller.textView.textContentStorage?.textStorage?.replaceCharacters(in: NSRange(location: 0, length: controller.textView.textContentStorage?.textStorage?.length ?? 0), with: "")
        controller.insertTab(nil)
        XCTAssertEqual(controller.textView.string, " ")

        // Insert 2 spaces
        controller.indentOption = .spaces(count: 2)
        controller.textView.textContentStorage?.textStorage?.replaceCharacters(in: NSRange(location: 0, length: controller.textView.textContentStorage?.textStorage?.length ?? 0), with: "")
        controller.textView.insertText("\t", replacementRange: .zero)
        XCTAssertEqual(controller.textView.string, "  ")

        // Insert 3 spaces
        controller.indentOption = .spaces(count: 3)
        controller.textView.textContentStorage?.textStorage?.replaceCharacters(in: NSRange(location: 0, length: controller.textView.textContentStorage?.textStorage?.length ?? 0), with: "")
        controller.textView.insertText("\t", replacementRange: .zero)
        XCTAssertEqual(controller.textView.string, "   ")

        // Insert 4 spaces
        controller.indentOption = .spaces(count: 4)
        controller.textView.textContentStorage?.textStorage?.replaceCharacters(in: NSRange(location: 0, length: controller.textView.textContentStorage?.textStorage?.length ?? 0), with: "")
        controller.textView.insertText("\t", replacementRange: .zero)
        XCTAssertEqual(controller.textView.string, "    ")

        // Insert tab
        controller.indentOption = .tab
        controller.textView.textContentStorage?.textStorage?.replaceCharacters(in: NSRange(location: 0, length: controller.textView.textContentStorage?.textStorage?.length ?? 0), with: "")
        controller.textView.insertText("\t", replacementRange: .zero)
        XCTAssertEqual(controller.textView.string, "\t")

        // Insert lots of spaces
        controller.indentOption = .spaces(count: 1000)
        controller.textView.textContentStorage?.textStorage?.replaceCharacters(in: NSRange(location: 0, length: controller.textView.textContentStorage?.textStorage?.length ?? 0), with: "")
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

    func test_bracketHighlights() {
        controller.viewDidLoad()
        controller.bracketPairHighlight = nil
        controller.textView.string = "{ Loren Ipsum {} }"
        controller.setCursorPosition((1, 2)) // After first opening {
        XCTAssert(controller.highlightLayers.isEmpty, "Controller added highlight layer when setting is set to `nil`")

        controller.bracketPairHighlight = .bordered
        controller.setCursorPosition((1, 2)) // After first opening {
        XCTAssert(controller.highlightLayers.count == 2, "Controller created an incorrect number of layers for the box. Expected 2, found \(controller.highlightLayers.count)")
        controller.setCursorPosition((1, 3))
        XCTAssert(controller.highlightLayers.isEmpty, "Controller failed to remove bracket pair layers.")

        controller.bracketPairHighlight = .flash
        controller.setCursorPosition((1, 2)) // After first opening {
        XCTAssert(controller.highlightLayers.count == 1, "Controller created more than one layer for flash animation. Expected 1, found \(controller.highlightLayers.count)")
        controller.setCursorPosition((1, 3))
        XCTAssert(controller.highlightLayers.isEmpty, "Controller failed to remove bracket pair layers.")

        controller.setCursorPosition((1, 2)) // After first opening {
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
}
// swiftlint:enable all
