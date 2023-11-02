//
//  TextSelectionManager.swift
//  
//
//  Created by Khan Winter on 7/17/23.
//

import AppKit
import Common

public protocol TextSelectionManagerDelegate: AnyObject {
    var visibleTextRange: NSRange? { get }

    func setNeedsDisplay()
    func estimatedLineHeight() -> CGFloat
}

/// Manages an array of text selections representing cursors (0-length ranges) and selections (>0-length ranges).
///
/// Draws selections using a draw method similar to the `TextLayoutManager` class, and adds cursor views when
/// appropriate.
public class TextSelectionManager: NSObject {
    struct MarkedText {
        let range: NSRange
        let attributedString: NSAttributedString
    }

    // MARK: - TextSelection

    public class TextSelection: Hashable {
        public var range: NSRange
        internal weak var view: CursorView?
        internal var boundingRect: CGRect = .zero
        internal var suggestedXPos: CGFloat?
        /// The position this selection should 'rotate' around when modifying selections.
        internal var pivot: Int?

        init(range: NSRange, view: CursorView? = nil) {
            self.range = range
            self.view = view
        }

        var isCursor: Bool {
            range.length == 0
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(range)
        }

        public static func == (lhs: TextSelection, rhs: TextSelection) -> Bool {
            lhs.range == rhs.range
        }
    }

    public enum Destination {
        case character
        case word
        case line
        case visualLine
        /// Eg: Bottom of screen
        case container
        case document
    }

    public enum Direction {
        case up
        case down
        case forward
        case backward
    }

    // MARK: - Properties

    // swiftlint:disable:next line_length
    public static let selectionChangedNotification: Notification.Name = Notification.Name("com.CodeEdit.TextSelectionManager.TextSelectionChangedNotification")

    public var insertionPointColor: NSColor = NSColor.labelColor {
        didSet {
            textSelections.forEach { $0.view?.color = insertionPointColor }
        }
    }
    public var highlightSelectedLine: Bool = true
    public var selectedLineBackgroundColor: NSColor = NSColor.selectedTextBackgroundColor.withSystemEffect(.disabled)
    public var selectionBackgroundColor: NSColor = NSColor.selectedTextBackgroundColor

    internal var markedText: [MarkedText] = []
    internal(set) public var textSelections: [TextSelection] = []
    internal weak var layoutManager: TextLayoutManager?
    internal weak var textStorage: NSTextStorage?
    internal weak var layoutView: NSView?
    internal weak var delegate: TextSelectionManagerDelegate?

    init(
        layoutManager: TextLayoutManager,
        textStorage: NSTextStorage,
        layoutView: NSView?,
        delegate: TextSelectionManagerDelegate?
    ) {
        self.layoutManager = layoutManager
        self.textStorage = textStorage
        self.layoutView = layoutView
        self.delegate = delegate
        super.init()
        textSelections = []
        updateSelectionViews()
    }

    // MARK: - Selected Ranges

    public func setSelectedRange(_ range: NSRange) {
        textSelections.forEach { $0.view?.removeFromSuperview() }
        let selection = TextSelection(range: range)
        selection.suggestedXPos = layoutManager?.rectForOffset(range.location)?.minX
        textSelections = [selection]
        updateSelectionViews()
        NotificationCenter.default.post(Notification(name: Self.selectionChangedNotification, object: self))
    }

    public func setSelectedRanges(_ ranges: [NSRange]) {
        textSelections.forEach { $0.view?.removeFromSuperview() }
        textSelections = Set(ranges).map {
            let selection = TextSelection(range: $0)
            selection.suggestedXPos = layoutManager?.rectForOffset($0.location)?.minX
            return selection
        }
        updateSelectionViews()
        NotificationCenter.default.post(Notification(name: Self.selectionChangedNotification, object: self))
    }

    public func addSelectedRange(_ range: NSRange) {
        let newTextSelection = TextSelection(range: range)
        var didHandle = false
        for textSelection in textSelections {
            if textSelection.range == newTextSelection.range {
                // Duplicate range, ignore
                return
            } else if (range.length > 0 && textSelection.range.intersection(range) != nil)
                        || textSelection.range.max == range.location {
                // Range intersects existing range, modify this range to be the union of both and don't add the new
                // selection
                textSelection.range = textSelection.range.union(range)
                didHandle = true
            }
        }
        if !didHandle {
            textSelections.append(newTextSelection)
        }

        updateSelectionViews()
        NotificationCenter.default.post(Notification(name: Self.selectionChangedNotification, object: self))
    }

    // MARK: - Selection Views

    func updateSelectionViews() {
        var didUpdate: Bool = false

        for textSelection in textSelections {
            if textSelection.range.isEmpty {
                let cursorOrigin = (layoutManager?.rectForOffset(textSelection.range.location) ?? .zero).origin
                if textSelection.view == nil
                    || textSelection.boundingRect.origin != cursorOrigin
                    || textSelection.boundingRect.height != layoutManager?.estimateLineHeight() ?? 0 {
                    textSelection.view?.removeFromSuperview()
                    textSelection.view = nil
                    let cursorView = CursorView(color: insertionPointColor)
                    cursorView.frame.origin = cursorOrigin
                    cursorView.frame.size.height = layoutManager?.estimateLineHeight() ?? 0
                    layoutView?.addSubview(cursorView)
                    textSelection.view = cursorView
                    textSelection.boundingRect = cursorView.frame
                    didUpdate = true
                }
            } else if !textSelection.range.isEmpty && textSelection.view != nil {
                textSelection.view?.removeFromSuperview()
                textSelection.view = nil
                didUpdate = true
            }
        }

        if didUpdate {
            delegate?.setNeedsDisplay()
        }
    }

    internal func removeCursors() {
        for textSelection in textSelections {
            textSelection.view?.removeFromSuperview()
        }
    }

    // MARK: - Draw

    /// Draws line backgrounds and selection rects for each selection in the given rect.
    /// - Parameter rect: The rect to draw in.
    internal func drawSelections(in rect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.saveGState()
        var highlightedLines: Set<UUID> = []
        // For each selection in the rect
        for textSelection in textSelections {
            if textSelection.range.isEmpty {
                drawHighlightedLine(
                    in: rect,
                    for: textSelection,
                    context: context,
                    highlightedLines: &highlightedLines
                )
            } else {
                drawSelectedRange(in: rect, for: textSelection, context: context)
            }
        }
        context.restoreGState()
    }

    /// Draws a highlighted line in the given rect.
    /// - Parameters:
    ///   - rect: The rect to draw in.
    ///   - textSelection: The selection to draw.
    ///   - context: The context to draw in.
    ///   - highlightedLines: The set of all lines that have already been highlighted, used to avoid highlighting lines
    ///                       twice and updated if this function comes across a new line id.
    private func drawHighlightedLine(
        in rect: NSRect,
        for textSelection: TextSelection,
        context: CGContext,
        highlightedLines: inout Set<UUID>
    ) {
        guard let linePosition = layoutManager?.textLineForOffset(textSelection.range.location),
              !highlightedLines.contains(linePosition.data.id) else {
            return
        }
        highlightedLines.insert(linePosition.data.id)
        context.saveGState()
        let selectionRect = CGRect(
            x: rect.minX,
            y: linePosition.yPos,
            width: rect.width,
            height: linePosition.height
        )
        if selectionRect.intersects(rect) {
            context.setFillColor(selectedLineBackgroundColor.cgColor)
            context.fill(selectionRect)
        }
        context.restoreGState()
    }

    /// Draws a selected range in the given context.
    /// - Parameters:
    ///   - rect: The rect to draw in.
    ///   - range: The range to highlight.
    ///   - context: The context to draw in.
    private func drawSelectedRange(in rect: NSRect, for textSelection: TextSelection, context: CGContext) {
        guard let layoutManager else { return }
        let range = textSelection.range
        context.saveGState()
        context.setFillColor(selectionBackgroundColor.cgColor)

        let fillRects = getFillRects(in: rect, for: textSelection)

        let min = fillRects.min(by: { $0.origin.y < $1.origin.y })?.origin ?? .zero
        let max = fillRects.max(by: { $0.origin.y < $1.origin.y }) ?? .zero
        let size = CGSize(width: max.maxX - min.x, height: max.maxY - min.y)
        textSelection.boundingRect = CGRect(origin: min, size: size)

        context.fill(fillRects)
        context.restoreGState()
    }
}

// MARK: - Private TextSelection

private extension TextSelectionManager.TextSelection {
    func didInsertText(length: Int, retainLength: Bool = false) {
        if !retainLength {
            range.length = 0
        }
        range.location += length
    }
}
