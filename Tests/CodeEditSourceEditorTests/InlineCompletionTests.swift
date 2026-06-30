import XCTest
@testable import CodeEditSourceEditor
import CodeEditTextView
import AppKit

@MainActor
final class MockInlineCompletionDelegate: InlineCompletionDelegate {
    let items: [InlineCompletionItem]
    private(set) var requestCount = 0
    private(set) var shownItems: [InlineCompletionItem] = []
    private(set) var acceptedItems: [InlineCompletionItem] = []
    private(set) var dismissedItems: [InlineCompletionItem] = []

    init(items: [InlineCompletionItem]) {
        self.items = items
    }

    func inlineCompletionsRequested(
        textView: TextViewController,
        cursorPosition: CursorPosition
    ) async -> [InlineCompletionItem] {
        requestCount += 1
        return items
    }

    func inlineCompletionDidShow(item: InlineCompletionItem) {
        shownItems.append(item)
    }

    func inlineCompletionDidAccept(item: InlineCompletionItem) {
        acceptedItems.append(item)
    }

    func inlineCompletionDidDismiss(item: InlineCompletionItem) {
        dismissedItems.append(item)
    }
}

@MainActor
final class InlineCompletionTests: XCTestCase {

    var controller: TextViewController!
    var theme: EditorTheme!
    var delegate: MockInlineCompletionDelegate!

    override func setUpWithError() throws {
        theme = Mock.theme()
        controller = Mock.textViewController(theme: theme)

        controller.loadView()
        controller.view.frame = NSRect(x: 0, y: 0, width: 1000, height: 1000)
        controller.view.layoutSubtreeIfNeeded()

        delegate = MockInlineCompletionDelegate(
            items: [InlineCompletionItem(insertText: "bar", range: NSRange(location: 3, length: 0))]
        )
        controller.inlineCompletionDelegate = delegate
    }

    override func tearDownWithError() throws {
        controller = nil
        theme = nil
        delegate = nil
    }

    private func prepare(text: String, cursorLocation: Int) {
        controller.setText(text)
        controller.textView.selectionManager.setSelectedRange(NSRange(location: cursorLocation, length: 0))
        controller.textView.layoutManager.layoutLines()
        controller.updateCursorPosition()
    }

    private func tabEvent() -> NSEvent {
        NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: "\t",
            charactersIgnoringModifiers: "\t",
            isARepeat: false,
            keyCode: 0x30
        )!
    }

    // MARK: Request

    func test_requestInlineSuggestion_setsActiveAndRendersGhostText() async throws {
        prepare(text: "foo", cursorLocation: 3)

        controller.requestInlineSuggestion()
        await controller.inlineCompletionTask?.value

        XCTAssertEqual(delegate.requestCount, 1)
        XCTAssertEqual(controller.activeInlineSuggestion?.insertText, "bar")
        XCTAssertNotNil(controller.textView.inlineSuggestionManager?.current)
        XCTAssertEqual(controller.textView.inlineSuggestionManager?.current?.text, "bar")
        XCTAssertEqual(delegate.shownItems.count, 1)
        // Ghost text must never mutate the document.
        XCTAssertEqual(controller.textView.string, "foo")
    }

    // MARK: Set

    func test_setInlineSuggestions_rendersAndNotifies() throws {
        prepare(text: "foo", cursorLocation: 3)
        let item = InlineCompletionItem(insertText: "bar", range: NSRange(location: 3, length: 0))

        controller.setInlineSuggestions([item])

        XCTAssertEqual(controller.activeInlineSuggestion?.id, item.id)
        XCTAssertNotNil(controller.textView.inlineSuggestionManager?.current)
        XCTAssertEqual(delegate.shownItems.map(\.id), [item.id])
    }

    // MARK: Accept

    func test_acceptInlineSuggestion_insertsTextAndClearsGhost() throws {
        prepare(text: "foo", cursorLocation: 3)
        let item = InlineCompletionItem(insertText: "bar", range: NSRange(location: 3, length: 0))
        controller.setInlineSuggestions([item])
        XCTAssertNotNil(controller.activeInlineSuggestion)

        let accepted = controller.acceptInlineSuggestion()

        XCTAssertTrue(accepted)
        XCTAssertEqual(controller.textView.string, "foobar")
        XCTAssertNil(controller.activeInlineSuggestion)
        XCTAssertNil(controller.textView.inlineSuggestionManager?.current)
        XCTAssertEqual(delegate.acceptedItems.map(\.id), [item.id])
    }

    func test_acceptInlineSuggestion_returnsFalseWhenInactive() throws {
        prepare(text: "foo", cursorLocation: 3)

        XCTAssertFalse(controller.acceptInlineSuggestion())
        XCTAssertEqual(controller.textView.string, "foo")
        XCTAssertTrue(delegate.acceptedItems.isEmpty)
    }

    // MARK: Dismiss

    func test_dismissInlineSuggestion_clearsWithoutInserting() throws {
        prepare(text: "foo", cursorLocation: 3)
        let item = InlineCompletionItem(insertText: "bar", range: NSRange(location: 3, length: 0))
        controller.setInlineSuggestions([item])

        let dismissed = controller.dismissInlineSuggestion()

        XCTAssertTrue(dismissed)
        XCTAssertEqual(controller.textView.string, "foo")
        XCTAssertNil(controller.activeInlineSuggestion)
        XCTAssertNil(controller.textView.inlineSuggestionManager?.current)
        XCTAssertEqual(delegate.dismissedItems.map(\.id), [item.id])
        XCTAssertTrue(delegate.acceptedItems.isEmpty)
    }

    // MARK: Cycling

    func test_cycleInlineSuggestions_reRendersSelectedItem() throws {
        prepare(text: "foo", cursorLocation: 3)
        let first = InlineCompletionItem(insertText: "one", range: NSRange(location: 3, length: 0))
        let second = InlineCompletionItem(insertText: "two", range: NSRange(location: 3, length: 0))
        controller.setInlineSuggestions([first, second])
        XCTAssertEqual(controller.activeInlineSuggestion?.id, first.id)

        controller.selectNextInlineSuggestion()
        XCTAssertEqual(controller.activeInlineSuggestion?.id, second.id)
        XCTAssertEqual(controller.textView.inlineSuggestionManager?.current?.text, "two")

        controller.selectNextInlineSuggestion()
        XCTAssertEqual(controller.activeInlineSuggestion?.id, first.id, "Cycling should wrap around.")

        controller.selectPreviousInlineSuggestion()
        XCTAssertEqual(controller.activeInlineSuggestion?.id, second.id, "Previous should wrap backwards.")
    }

    // MARK: Clearing

    func test_cursorMoveClearsGhostText() throws {
        prepare(text: "foo", cursorLocation: 3)
        let item = InlineCompletionItem(insertText: "bar", range: NSRange(location: 3, length: 0))
        controller.setInlineSuggestions([item])
        XCTAssertNotNil(controller.activeInlineSuggestion)

        controller.textView.selectionManager.setSelectedRange(NSRange(location: 0, length: 0))
        controller.updateCursorPosition()

        XCTAssertNil(controller.activeInlineSuggestion)
        XCTAssertNil(controller.textView.inlineSuggestionManager?.current)
    }

    func test_editClearsGhostText() throws {
        prepare(text: "foo", cursorLocation: 3)
        let item = InlineCompletionItem(insertText: "bar", range: NSRange(location: 3, length: 0))
        controller.setInlineSuggestions([item])
        XCTAssertNotNil(controller.activeInlineSuggestion)

        controller.textView.replaceCharacters(in: NSRange(location: 3, length: 0), with: "x")

        XCTAssertNil(controller.activeInlineSuggestion)
        XCTAssertNil(controller.textView.inlineSuggestionManager?.current)
    }

    // MARK: Tab

    func test_tabAcceptsOnlyWhenActive() throws {
        prepare(text: "foo", cursorLocation: 3)

        // Inactive: Tab is passed through and the document is unchanged.
        let passthrough = controller.handleTab(event: tabEvent(), modifierFlags: 0)
        XCTAssertNotNil(passthrough, "Tab should be passed through when no suggestion is active.")
        XCTAssertEqual(controller.textView.string, "foo")

        // Active: Tab is consumed and the suggestion is accepted.
        let item = InlineCompletionItem(insertText: "bar", range: NSRange(location: 3, length: 0))
        controller.setInlineSuggestions([item])
        let consumed = controller.handleTab(event: tabEvent(), modifierFlags: 0)
        XCTAssertNil(consumed, "Tab should be consumed when a suggestion is active.")
        XCTAssertEqual(controller.textView.string, "foobar")
        XCTAssertEqual(delegate.acceptedItems.map(\.id), [item.id])
    }
}
