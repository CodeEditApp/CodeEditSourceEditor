//
//  TextView.swift
//  
//
//  Created by Khan Winter on 6/21/23.
//

import AppKit
import Common
import TextStory

/**

```
 TextView
 |-> TextLayoutManager          Creates, manages, and lays out text lines from a line storage
 |  |-> [TextLine]              Represents a text line
 |  |   |-> Typesetter          Lays out and calculates line fragments
 |  |   |-> [LineFragment]      Represents a visual text line, stored in a line storage for long lines
 |  |-> [LineFragmentView]      Reusable line fragment view that draws a line fragment.
 |
 |-> TextSelectionManager       Maintains, modifies, and renders text selections
 |  |-> [TextSelection]
 ```
 */
public class TextView: NSView, NSTextContent {
    // MARK: - Configuration

    func setString(_ string: String) {
        textStorage.setAttributedString(.init(string: string))
    }

    public var font: NSFont {
        didSet {
            setNeedsDisplay()
            layoutManager.setNeedsLayout()
        }
    }
    public var lineHeight: CGFloat
    public var wrapLines: Bool
    public var editorOverscroll: CGFloat
    public var isEditable: Bool
    @Invalidating(.display)
    public var isSelectable: Bool = true
    public var letterSpacing: Double
    public var edgeInsets: HorizontalEdgeInsets = .zero {
        didSet {
            layoutManager.edgeInsets = edgeInsets
            selectionManager.updateSelectionViews()
        }
    }

    open var contentType: NSTextContentType?

    public weak var delegate: TextViewDelegate?

    public var textStorage: NSTextStorage! {
        didSet {
            setUpLayoutManager()
            setUpSelectionManager()
            needsDisplay = true
            needsLayout = true
        }
    }
    private(set) public var layoutManager: TextLayoutManager!
    private(set) public var selectionManager: TextSelectionManager!

    // MARK: - Private Properties

    internal var isFirstResponder: Bool = false
    internal var mouseDragAnchor: CGPoint?
    internal var mouseDragTimer: Timer?

    var _undoManager: CEUndoManager?
    @objc dynamic open var allowsUndo: Bool

    var scrollView: NSScrollView? {
        guard let enclosingScrollView, enclosingScrollView.documentView == self else { return nil }
        return enclosingScrollView
    }

    private weak var storageDelegate: MultiStorageDelegate!

    // MARK: - Init

    public init(
        string: String,
        font: NSFont,
        lineHeight: CGFloat,
        wrapLines: Bool,
        editorOverscroll: CGFloat,
        isEditable: Bool,
        letterSpacing: Double,
        delegate: TextViewDelegate,
        storageDelegate: MultiStorageDelegate
    ) {
        self.delegate = delegate
        self.textStorage = NSTextStorage(string: string)
        self.storageDelegate = storageDelegate

        self.font = font
        self.lineHeight = lineHeight
        self.wrapLines = wrapLines
        self.editorOverscroll = editorOverscroll
        self.isEditable = isEditable
        self.letterSpacing = letterSpacing
        self.allowsUndo = true

        super.init(frame: .zero)

        wantsLayer = true
        postsFrameChangedNotifications = true
        postsBoundsChangedNotifications = true
        autoresizingMask = [.width, .height]

        // TODO: Implement typing/default attributes
        textStorage.addAttributes([.font: font], range: documentRange)
        textStorage.delegate = storageDelegate

        layoutManager = setUpLayoutManager()
        storageDelegate.addDelegate(layoutManager)
        selectionManager = setUpSelectionManager()
        storageDelegate.addDelegate(selectionManager)

        _undoManager = CEUndoManager(textView: self)

        layoutManager.layoutLines()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var documentRange: NSRange {
        NSRange(location: 0, length: textStorage.length)
    }

    // MARK: - First Responder

    open override func becomeFirstResponder() -> Bool {
        isFirstResponder = true
        return super.becomeFirstResponder()
    }

    open override func resignFirstResponder() -> Bool {
        isFirstResponder = false
        selectionManager.removeCursors()
        return super.resignFirstResponder()
    }

    open override var canBecomeKeyView: Bool {
        super.canBecomeKeyView && acceptsFirstResponder && !isHiddenOrHasHiddenAncestor
    }

    open override var needsPanelToBecomeKey: Bool {
        isSelectable || isEditable
    }

    open override var acceptsFirstResponder: Bool {
        isSelectable
    }

    open override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    open override func resetCursorRects() {
        super.resetCursorRects()
        if isSelectable {
            addCursorRect(visibleRect, cursor: .iBeam)
        }
    }

    // MARK: - View Lifecycle

    override public func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: newWindow)
        layoutManager.layoutLines()
    }

    override public func viewDidEndLiveResize() {
        super.viewDidEndLiveResize()
        updateFrameIfNeeded()
    }

    // MARK: - Interaction

    override public func keyDown(with event: NSEvent) {
        guard isEditable else {
            super.keyDown(with: event)
            return
        }

        NSCursor.setHiddenUntilMouseMoves(true)

        if !(inputContext?.handleEvent(event) ?? false) {
            interpretKeyEvents([event])
        } else {
            // Handle key events?
        }
    }

    override public func mouseDown(with event: NSEvent) {
        // Set cursor
        guard let offset = layoutManager.textOffsetAtPoint(self.convert(event.locationInWindow, from: nil)) else {
            super.mouseDown(with: event)
            return
        }
        if isSelectable {
            selectionManager.setSelectedRange(NSRange(location: offset, length: 0))
        }

        mouseDragTimer?.invalidate()
        // https://cocoadev.github.io/AutoScrolling/ (fired at ~45Hz)
        mouseDragTimer = Timer.scheduledTimer(withTimeInterval: 0.022, repeats: true) { [weak self] _ in
            if let event = self?.window?.currentEvent, event.type == .leftMouseDragged {
                self?.mouseDragged(with: event)
                self?.autoscroll(with: event)
            }
        }

        if !self.isFirstResponder {
            self.window?.makeFirstResponder(self)
        }
    }

    override public func mouseUp(with event: NSEvent) {
        mouseDragAnchor = nil
        mouseDragTimer?.invalidate()
        mouseDragTimer = nil
        super.mouseUp(with: event)
    }

    // MARK: - Layout

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if isSelectable {
            selectionManager.drawSelections(in: dirtyRect)
        }
    }

    override open var isFlipped: Bool {
        true
    }

    override public var visibleRect: NSRect {
        if let scrollView = scrollView {
            var rect = scrollView.documentVisibleRect
            rect.origin.y += scrollView.contentInsets.top
            rect.size.height -= scrollView.contentInsets.top + scrollView.contentInsets.bottom
            return rect
        } else {
            return super.visibleRect
        }
    }

    public var visibleTextRange: NSRange? {
        let minY = max(visibleRect.minY, 0)
        let maxY = min(visibleRect.maxY, layoutManager.estimatedHeight())
        guard let minYLine = layoutManager.textLineForPosition(minY),
              let maxYLine = layoutManager.textLineForPosition(maxY) else {
            return nil
        }
        return NSRange(
            location: minYLine.range.location,
            length: (maxYLine.range.location - minYLine.range.location) + maxYLine.range.length
        )
    }

    public func updatedViewport(_ newRect: CGRect) {
        if !updateFrameIfNeeded() {
            layoutManager.layoutLines()
        }
        inputContext?.invalidateCharacterCoordinates()
    }

    @discardableResult
    public func updateFrameIfNeeded() -> Bool {
        var availableSize = scrollView?.contentSize ?? .zero
        availableSize.height -= (scrollView?.contentInsets.top ?? 0) + (scrollView?.contentInsets.bottom ?? 0)
        let newHeight = layoutManager.estimatedHeight()
        let newWidth = layoutManager.estimatedWidth()

        var didUpdate = false

        if newHeight + editorOverscroll >= availableSize.height && frame.size.height != newHeight + editorOverscroll {
            frame.size.height = newHeight + editorOverscroll
            // No need to update layout after height adjustment
        }

        if wrapLines && frame.size.width != availableSize.width {
            frame.size.width = availableSize.width
            didUpdate = true
        } else if !wrapLines && frame.size.width != max(newWidth, availableSize.width) {
            frame.size.width = max(newWidth, availableSize.width)
            didUpdate = true
        }

        if didUpdate {
            needsLayout = true
            needsDisplay = true
            layoutManager.layoutLines()
        }

        if isSelectable {
            selectionManager?.updateSelectionViews()
        }

        return didUpdate
    }

    /// Scrolls the upmost selection to the visible rect if `scrollView` is not `nil`.
    public func scrollSelectionToVisible() {
        guard let scrollView,
              let selection = selectionManager.textSelections
            .sorted(by: { $0.boundingRect.origin.y < $1.boundingRect.origin.y }).first else {
            return
        }
        var lastFrame: CGRect = .zero
        while lastFrame != selection.boundingRect {
            lastFrame = selection.boundingRect
            layoutManager.layoutLines()
            selectionManager.updateSelectionViews()
            selectionManager.drawSelections(in: visibleRect)
        }
        scrollView.contentView.scrollToVisible(lastFrame)
    }

    deinit {
        layoutManager = nil
        selectionManager = nil
        textStorage = nil
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - TextSelectionManagerDelegate

extension TextView: TextSelectionManagerDelegate {
    public func setNeedsDisplay() {
        self.setNeedsDisplay(visibleRect)
    }

    public func estimatedLineHeight() -> CGFloat {
        layoutManager.estimateLineHeight()
    }
}
