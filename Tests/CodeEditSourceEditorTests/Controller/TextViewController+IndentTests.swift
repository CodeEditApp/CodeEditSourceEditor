//
//  TextViewController+IndentTests.swift
//  CodeEditSourceEditor
//
//  Created by Ludwig, Tom on 08.10.24.
//

import XCTest
@testable import CodeEditSourceEditor

final class TextViewControllerIndentTests: XCTestCase {
    var controller: TextViewController!

    override func setUpWithError() throws {
        controller = Mock.textViewController(theme: Mock.theme())

        controller.loadView()
    }

    func testHandleIndentWithSpacesInwards() {
        controller.setText("    This is a test string")
        let cursorPositions = [CursorPosition(range: NSRange(location: 0, length: 0))]
        controller.cursorPositions = cursorPositions
        controller.handleIndent(inwards: true)

        XCTAssertEqual(controller.string, "This is a test string")

        // Normally, 4 spaces are used for indentation; however, now we only insert 2 leading spaces.
        // The outcome should be the same, though.
        controller.setText("  This is a test string")
        controller.cursorPositions = cursorPositions
        controller.handleIndent(inwards: true)

        XCTAssertEqual(controller.string, "This is a test string")
    }

    func testHandleIndentWithSpacesOutwards() {
        controller.setText("This is a test string")
        let cursorPositions = [CursorPosition(range: NSRange(location: 0, length: 0))]
        controller.cursorPositions = cursorPositions

        controller.handleIndent(inwards: false)

        XCTAssertEqual(controller.string, "    This is a test string")
    }

    func testHandleIndentWithTabsInwards() {
        controller.setText("\tThis is a test string")
        controller.indentOption = .tab
        let cursorPositions = [CursorPosition(range: NSRange(location: 0, length: 0))]
        controller.cursorPositions = cursorPositions

        controller.handleIndent(inwards: true)

        XCTAssertEqual(controller.string, "This is a test string")
    }

    func testHandleIndentWithTabsOutwards() {
        controller.setText("This is a test string")
        controller.indentOption = .tab
        let cursorPositions = [CursorPosition(range: NSRange(location: 0, length: 0))]
        controller.cursorPositions = cursorPositions

        controller.handleIndent()

        // Normally, we expect nothing to happen because only one line is selected.
        // However, this logic is not handled inside `handleIndent`.
        XCTAssertEqual(controller.string, "\tThis is a test string")
    }

    func testHandleIndentMultiLine() {
        controller.indentOption = .tab
        controller.setText("This is a test string\nWith multiple lines\nAnd some indentation")
        let cursorPositions = [CursorPosition(range: NSRange(location: 0, length: 5))]
        controller.cursorPositions = cursorPositions

        controller.handleIndent()
        let expectedString = "\tThis is a test string\nWith multiple lines\nAnd some indentation"
        XCTAssertEqual(controller.string, expectedString)
    }

    func testHandleInwardIndentMultiLine() {
        controller.indentOption = .tab
        controller.setText("\tThis is a test string\n\tWith multiple lines\n\tAnd some indentation")
        let cursorPositions = [CursorPosition(range: NSRange(location: 0, length: controller.string.count))]
        controller.cursorPositions = cursorPositions

        controller.handleIndent(inwards: true)
        let expectedString = "This is a test string\nWith multiple lines\nAnd some indentation"
        XCTAssertEqual(controller.string, expectedString)
    }

    func testMultipleLinesHighlighted() {
        controller.setText("\tThis is a test string\n\tWith multiple lines\n\tAnd some indentation")
        var cursorPositions = [CursorPosition(range: NSRange(location: 0, length: controller.string.count))]
        controller.cursorPositions = cursorPositions

        XCTAssert(controller.multipleLinesHighlighted())

        cursorPositions = [CursorPosition(range: NSRange(location: 0, length: 5))]
        controller.cursorPositions = cursorPositions

        XCTAssertFalse(controller.multipleLinesHighlighted())
    }
}
