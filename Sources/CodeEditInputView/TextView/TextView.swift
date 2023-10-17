//
//  TextView.swift
//  
//
//  Created by Khan Winter on 6/21/23.
//

import AppKit
import Common
import TextStory

// Disabling file length and type body length as the methods and variables contained in this file cannot be moved
// to extensions without a lot of work.
// swiftlint:disable type_body_length

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
    // MARK: - Statics

    /// The default typing attributes. Defaults to:
    /// - font: System font, size 12
    /// - foregroundColor: System text color
    /// - kern: 0.0
    static public var defaultTypingAttributes: [NSAttributedString.Key: Any] {
        [.font: NSFont.systemFont(ofSize: 12), .foregroundColor: NSColor.textColor, .kern: 0.0]
    }

    // MARK: - Configuration

    public var string: String {
        get {
            textStorage.string
        }
        set {
            layoutManager.willReplaceCharactersInRange(range: documentRange, with: newValue)
            textStorage.setAttributedString(NSAttributedString(string: newValue, attributes: typingAttributes))
        }
    }

    /// The attributes to apply to inserted text.
    public var typingAttributes: [NSAttributedString.Key: Any] = [:] {
        didSet {
            setNeedsDisplay()
            layoutManager?.setNeedsLayout()
        }
    }

    /// The default font of the text view.
    public var font: NSFont {
        get {
            (typingAttributes[.font] as? NSFont) ?? NSFont.systemFont(ofSize: 12)
        }
        set {
            typingAttributes[.font] = newValue
        }
    }

    /// The text color of the text view.
    public var textColor: NSColor {
        get {
            (typingAttributes[.foregroundColor] as? NSColor) ?? NSColor.textColor
        }
        set {
            typingAttributes[.foregroundColor] = newValue
        }
    }

    /// The line height as a multiple of the font's line height. 1.0 represents no change in height.
    public var lineHeight: CGFloat {
        get {
            layoutManager?.lineHeightMultiplier ?? 1.0
        }
        set {
            layoutManager?.lineHeightMultiplier = newValue
        }
    }

    /// Whether or not the editor should wrap lines
    public var wrapLines: Bool {
        get {
            layoutManager?.wrapLines ?? false
        }
        set {
            layoutManager?.wrapLines = newValue
        }
    }

    /// A multiplier that determines the amount of space between characters. `1.0` indicates no space,
    /// `2.0` indicates one character of space between other characters.
    public var letterSpacing: Double {
        didSet {
            kern = fontCharWidth * (letterSpacing - 1.0)
            layoutManager.setNeedsLayout()
        }
    }

    public var isEditable: Bool {
        didSet {
            setNeedsDisplay()
            selectionManager.updateSelectionViews()
            if !isEditable && isFirstResponder {
                _ = resignFirstResponder()
            }
        }
    }

    public var isSelectable: Bool = true {
        didSet {
            if !isSelectable {
                selectionManager.removeCursors()
                if isFirstResponder {
                    _ = resignFirstResponder()
                }
            }
            setNeedsDisplay()
        }
    }

    public var edgeInsets: HorizontalEdgeInsets {
        get {
            layoutManager?.edgeInsets ?? .zero
        }
        set {
            layoutManager?.edgeInsets = newValue
        }
    }

    /// The kern to use for characters. Defaults to `0.0` and is updated when `letterSpacing` is set.
    public var kern: CGFloat {
        get {
            typingAttributes[.kern] as? CGFloat ?? 0
        }
        set {
            typingAttributes[.kern] = newValue
        }
    }

    open var contentType: NSTextContentType?

    public weak var delegate: TextViewDelegate?

    private(set) public var textStorage: NSTextStorage!
    private(set) public var layoutManager: TextLayoutManager!
    private(set) public var selectionManager: TextSelectionManager!

    // MARK: - Private Properties

    internal var isFirstResponder: Bool = false
    internal var mouseDragAnchor: CGPoint?
    internal var mouseDragTimer: Timer?

    private var fontCharWidth: CGFloat {
        (" " as NSString).size(withAttributes: [.font: font]).width
    }

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
        textColor: NSColor,
        lineHeight: CGFloat,
        wrapLines: Bool,
        isEditable: Bool,
        letterSpacing: Double,
        delegate: TextViewDelegate,
        storageDelegate: MultiStorageDelegate
    ) {
        self.delegate = delegate
        self.textStorage = NSTextStorage(string: string)
        self.storageDelegate = storageDelegate
        self.isEditable = isEditable
        self.letterSpacing = letterSpacing
        self.allowsUndo = true

        super.init(frame: .zero)

        wantsLayer = true
        postsFrameChangedNotifications = true
        postsBoundsChangedNotifications = true
        autoresizingMask = [.width, .height]

        self.typingAttributes = [
            .font: font,
            .foregroundColor: textColor,
        ]

        textStorage.addAttributes(typingAttributes, range: documentRange)
        textStorage.delegate = storageDelegate

        layoutManager = setUpLayoutManager(lineHeight: lineHeight, wrapLines: wrapLines)
        storageDelegate.addDelegate(layoutManager)
        selectionManager = setUpSelectionManager()
        storageDelegate.addDelegate(selectionManager)

        _undoManager = CEUndoManager(textView: self)

        layoutManager.layoutLines()
    }

    /// Set a new text storage object for the view.
    /// - Parameter textStorage: The new text storage to use.
    public func setTextStorage(_ textStorage: NSTextStorage) {
        let lineHeight = layoutManager.lineHeightMultiplier
        let wrapLines = layoutManager.wrapLines
        layoutManager = setUpLayoutManager(lineHeight: lineHeight, wrapLines: wrapLines)
        storageDelegate.addDelegate(layoutManager)
        selectionManager = setUpSelectionManager()
        storageDelegate.addDelegate(selectionManager)
        _undoManager?.clearStack()
        needsDisplay = true
        needsLayout = true
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
        let newHeight = max(layoutManager.estimatedHeight(), availableSize.height)
        let newWidth = layoutManager.estimatedWidth()

        var didUpdate = false

        if newHeight >= availableSize.height && frame.size.height != newHeight {
            frame.size.height = newHeight
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
        self.setNeedsDisplay(frame)
    }

    public func estimatedLineHeight() -> CGFloat {
        layoutManager.estimateLineHeight()
    }
}

// swiftlint:enable type_body_length
// swiftlint:disable:this file_length
