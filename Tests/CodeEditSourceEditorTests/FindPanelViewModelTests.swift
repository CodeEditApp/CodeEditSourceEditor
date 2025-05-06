//
//  FindPanelViewModelTests.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 4/25/25.
//

import Testing
import AppKit
import CodeEditTextView
@testable import CodeEditSourceEditor

@MainActor
struct FindPanelViewModelTests {
    class MockPanelTarget: FindPanelTarget {
        var emphasisManager: EmphasisManager?
        var text: String = ""
        var findPanelTargetView: NSView
        var cursorPositions: [CursorPosition] = []
        var textView: TextView!

        @MainActor init() {
            findPanelTargetView = NSView()
            textView = TextView(string: text)
        }

        func setCursorPositions(_ positions: [CursorPosition], scrollToVisible: Bool) { }
        func updateCursorPosition() { }
        func findPanelWillShow(panelHeight: CGFloat) { }
        func findPanelWillHide(panelHeight: CGFloat) { }
        func findPanelModeDidChange(to mode: FindPanelMode) { }
    }

    @Test func viewModelHeightUpdates() async throws {
        let model = FindPanelViewModel(target: MockPanelTarget())
        model.mode = .find
        #expect(model.panelHeight == 28)

        model.mode = .replace
        #expect(model.panelHeight == 54)
    }
}
