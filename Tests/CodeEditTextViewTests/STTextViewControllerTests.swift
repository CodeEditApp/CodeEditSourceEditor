import XCTest
@testable import CodeEditTextView
import SwiftTreeSitter
import AppKit
import TextStory

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
            wrapLines: true,
            cursorPosition: .constant((1, 1)),
            editorOverscroll: 0.5,
            useThemeBackground: true,
            isEditable: true
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
        controller.textView.string = ""
        controller.insertTab(nil)
        XCTAssertEqual(controller.textView.string, " ")

        // Insert 2 spaces
        controller.indentOption = .spaces(count: 2)
        controller.textView.string = ""
        controller.textView.insertText("\t", replacementRange: .zero)
        XCTAssertEqual(controller.textView.string, "  ")

        // Insert 3 spaces
        controller.indentOption = .spaces(count: 3)
        controller.textView.string = ""
        controller.textView.insertText("\t", replacementRange: .zero)
        XCTAssertEqual(controller.textView.string, "   ")

        // Insert 4 spaces
        controller.indentOption = .spaces(count: 4)
        controller.textView.string = ""
        controller.textView.insertText("\t", replacementRange: .zero)
        XCTAssertEqual(controller.textView.string, "    ")

        // Insert tab
        controller.indentOption = .tab
        controller.textView.string = ""
        controller.textView.insertText("\t", replacementRange: .zero)
        XCTAssertEqual(controller.textView.string, "\t")


        // Insert lots of spaces
        controller.indentOption = .spaces(count: 1000)
        controller.textView.string = ""
        controller.textView.insertText("\t", replacementRange: .zero)
        XCTAssertEqual(controller.textView.string, String(repeating: " ", count: 1000))
    }
}
