//
//  TextView.swift
//  
//
//  Created by Khan Winter on 6/21/23.
//

import AppKit
import TextStory

// Disabling file length and type body length as the methods and variables contained in this file cannot be moved
// to extensions.
// swiftlint:disable type_body_length

/// # Text View
///
/// A view that draws and handles user interactions with text.
/// Optimized for line-based documents, does not attempt to have feature parity with `NSTextView`.
///
/// The text view maintains multiple helper classes for selecting, editing, and laying out text.
/// ```
/// TextView
/// |-> NSTextStorage              Base text storage.
/// |-> TextLayoutManager          Creates, manages, and lays out text lines.
/// |  |-> TextLineStorage         Extremely fast object for storing and querying lines of text. Does not store text.
/// |  |-> [TextLine]              Represents a line of text.
/// |  |   |-> Typesetter          Calculates line breaks and other layout information for text lines.
/// |  |   |-> [LineFragment]      Represents a visual line of text, stored in an internal line storage object.
/// |  |-> [LineFragmentView]      Reusable line fragment view that draws a line fragment.
/// |  |-> MarkedRangeManager      Manages marked ranges, updates layout if needed.
/// |
/// |-> TextSelectionManager       Maintains, modifies, and renders text selections
/// |  |-> [TextSelection]         Represents a range of selected text.
/// ```
///
/// Conforms to [`NSTextContent`](https://developer.apple.com/documentation/appkit/nstextcontent) and
/// [`NSTextInputClient`](https://developer.apple.com/documentation/appkit/nstextinputclient) to work well with system
/// text interactions such as inserting text and marked text.
///
public class TextView: NSView, NSTextContent {
    // MARK: - Statics

    /// The default typing attributes:
    /// - font: System font, size 12
    /// - foregroundColor: System text color
    /// - kern: 0.0
    public static var defaultTypingAttributes: [NSAttributedString.Key: Any] {
        [.font: NSFont.systemFont(ofSize: 12), .foregroundColor: NSColor.textColor, .kern: 0.0]
    }

    // swiftlint:disable:next line_length
    public static let textDidChangeNotification: Notification.Name = .init(rawValue: "com.CodeEdit.TextView.TextDidChangeNotification")

    // swiftlint:disable:next line_length
    public static let textWillChangeNotification: Notification.Name = .init(rawValue: "com.CodeEdit.TextView.TextWillChangeNotification")

    // MARK: - Configuration

    /// The string for the text view.
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

    /// Determines if the text view's content can be edited.
    public var isEditable: Bool {
        didSet {
            setNeedsDisplay()
            selectionManager.updateSelectionViews()
            if !isEditable && isFirstResponder {
                _ = resignFirstResponder()
            }
        }
    }

    /// Determines if the text view responds to selection events, such as clicks.
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

    /// The edge insets for the text view.
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

    /// The strategy to use when breaking lines. Defaults to ``LineBreakStrategy/word``.
    public var lineBreakStrategy: LineBreakStrategy {
        get {
            layoutManager?.lineBreakStrategy ?? .word
        }
        set {
            layoutManager.lineBreakStrategy = newValue
        }
    }

    open var contentType: NSTextContentType?

    /// The text view's delegate.
    public weak var delegate: TextViewDelegate?

    /// The text storage object for the text view.
    /// - Warning: Do not update the text storage object directly. Doing so will very likely break the text view's
    ///            layout system. Use methods like ``TextView/replaceCharacters(in:with:)-3h9uo`` or
    ///            ``TextView/insertText(_:)`` to modify content.
    private(set) public var textStorage: NSTextStorage!
    /// The layout manager for the text view.
    private(set) public var layoutManager: TextLayoutManager!
    /// The selection manager for the text view.
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

    internal var storageDelegate: MultiStorageDelegate!

    // MARK: - Init

    /// Initializes the text view.
    /// - Parameters:
    ///   - string: The contents of the text view.
    ///   - font: The default font.
    ///   - textColor: The default text color.
    ///   - lineHeightMultiplier: The multiplier to use for line heights.
    ///   - wrapLines: Determines how the view will wrap lines to the viewport.
    ///   - isEditable: Determines if the view is editable.
    ///   - isSelectable: Determines if the view is selectable.
    ///   - letterSpacing: Sets the letter spacing on the view.
    ///   - delegate: The text view's delegate.
    public init(
        string: String,
        font: NSFont,
        textColor: NSColor,
        lineHeightMultiplier: CGFloat,
        wrapLines: Bool,
        isEditable: Bool,
        isSelectable: Bool,
        letterSpacing: Double,
        delegate: TextViewDelegate
    ) {
        self.textStorage = NSTextStorage(string: string)
        self.delegate = delegate
        self.isEditable = isEditable
        self.isSelectable = isSelectable
        self.letterSpacing = letterSpacing
        self.allowsUndo = true

        super.init(frame: .zero)

        self.storageDelegate = MultiStorageDelegate()

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

        layoutManager = setUpLayoutManager(lineHeightMultiplier: lineHeightMultiplier, wrapLines: wrapLines)
        storageDelegate.addDelegate(layoutManager)
        selectionManager = setUpSelectionManager()

        _undoManager = CEUndoManager(textView: self)

        layoutManager.layoutLines()
        setUpDragGesture()
    }

    /// Sets the text view's text to a new value.
    /// - Parameter text: The new contents of the text view.
    public func setText(_ text: String) {
        let newStorage = NSTextStorage(string: text)
        self.setTextStorage(newStorage)
    }

    /// Set a new text storage object for the view.
    /// - Parameter textStorage: The new text storage to use.
    public func setTextStorage(_ textStorage: NSTextStorage) {
        self.textStorage = textStorage

        subviews.forEach { view in
            view.removeFromSuperview()
        }

        textStorage.addAttributes(typingAttributes, range: documentRange)
        layoutManager.textStorage = textStorage
        layoutManager.reset()

        selectionManager.textStorage = textStorage
        selectionManager.setSelectedRanges(selectionManager.textSelections.map { $0.range })

        _undoManager?.clearStack()

        textStorage.delegate = storageDelegate
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

    override public func layout() {
        layoutManager.layoutLines()
        super.layout()
    }

    override public func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: newWindow)
        layoutManager.layoutLines()
    }

    override public func viewDidEndLiveResize() {
        super.viewDidEndLiveResize()
        updateFrameIfNeeded()
    }

    // MARK: - Key Down

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
