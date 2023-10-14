//
//  TextSelectionManager.swift
//  
//
//  Created by Khan Winter on 7/17/23.
//

import AppKit
import Common

public protocol TextSelectionManagerDelegate: AnyObject {
    var font: NSFont { get }

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

    public class TextSelection {
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

    open class var selectionChangedNotification: Notification.Name {
        Notification.Name("TextSelectionManager.TextSelectionChangedNotification")
    }

    public var insertionPointColor: NSColor = NSColor.labelColor {
        didSet {
            textSelections.forEach { $0.view?.color = insertionPointColor }
        }
    }
    public var highlightSelectedLine: Bool = true
    public var selectedLineBackgroundColor: NSColor = NSColor.selectedTextBackgroundColor.withSystemEffect(.disabled)
    public var selectionBackgroundColor: NSColor = NSColor.selectedTextBackgroundColor

    private var markedText: [MarkedText] = []
    private(set) public var textSelections: [TextSelection] = []
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
        textSelections = ranges.map {
            let selection = TextSelection(range: $0)
            selection.suggestedXPos = layoutManager?.rectForOffset($0.location)?.minX
            return selection
        }
        updateSelectionViews()
        NotificationCenter.default.post(Notification(name: Self.selectionChangedNotification, object: self))
    }

    // MARK: - Selection Views

    func updateSelectionViews() {
        var didUpdate: Bool = false

        for textSelection in textSelections {
            if textSelection.range.isEmpty {
                let lineFragment = layoutManager?
                    .textLineForOffset(textSelection.range.location)?
                    .data
                    .lineFragments
                    .first
                let cursorOrigin = (layoutManager?.rectForOffset(textSelection.range.location) ?? .zero).origin
                if textSelection.view == nil
                    || textSelection.boundingRect.origin != cursorOrigin
                    || textSelection.boundingRect.height != lineFragment?.data.scaledHeight ?? 0 {
                    textSelection.view?.removeFromSuperview()
                    let cursorView = CursorView(color: insertionPointColor)
                    cursorView.frame.origin = cursorOrigin
                    cursorView.frame.size.height = lineFragment?.data.scaledHeight ?? 0
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
        // For each selection in the rect
        for textSelection in textSelections {
            if textSelection.range.isEmpty {
                drawHighlightedLine(in: rect, for: textSelection, context: context)
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
    private func drawHighlightedLine(in rect: NSRect, for textSelection: TextSelection, context: CGContext) {
        guard let linePosition = layoutManager?.textLineForOffset(textSelection.range.location) else {
            return
        }
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

        var fillRects = [CGRect]()

        for linePosition in layoutManager.lineStorage.linesInRange(range) {
            if linePosition.range.intersection(range) == linePosition.range {
                // If the selected range contains the entire line
                fillRects.append(CGRect(
                    x: rect.minX,
                    y: linePosition.yPos,
                    width: rect.width,
                    height: linePosition.height
                ))
            } else {
                // The selected range contains some portion of the line
                for fragmentPosition in linePosition.data.lineFragments {
                    guard let fragmentRange = fragmentPosition
                        .range
                        .shifted(by: linePosition.range.location),
                          let intersectionRange = fragmentRange.intersection(range),
                          let minRect = layoutManager.rectForOffset(intersectionRange.location) else {
                        continue
                    }

                    let maxRect: CGRect
                    if fragmentRange.max <= range.max || range.contains(fragmentRange.max) {
                        maxRect = CGRect(
                            x: rect.maxX,
                            y: fragmentPosition.yPos + linePosition.yPos,
                            width: 0,
                            height: fragmentPosition.height
                        )
                    } else if let maxFragmentRect = layoutManager.rectForOffset(intersectionRange.max) {
                        maxRect = maxFragmentRect
                    } else {
                        continue
                    }

                    fillRects.append(CGRect(
                        x: minRect.origin.x,
                        y: minRect.origin.y,
                        width: maxRect.minX - minRect.minX,
                        height: max(minRect.height, maxRect.height)
                    ))
                }
            }
        }

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

// MARK: - Text Storage Delegate

extension TextSelectionManager: NSTextStorageDelegate {
    public func textStorage(
        _ textStorage: NSTextStorage,
        didProcessEditing editedMask: NSTextStorageEditActions,
        range editedRange: NSRange,
        changeInLength delta: Int
    ) {
        guard editedMask.contains(.editedCharacters) else { return }
        for textSelection in textSelections {
            if textSelection.range.max < editedRange.location {
                textSelection.range.location += delta
                textSelection.range.length = 0
            } else if textSelection.range.intersection(editedRange) != nil {
                if delta > 0 {
                    textSelection.range.location = editedRange.max
                } else {
                    textSelection.range.location = editedRange.location
                }
                textSelection.range.length = 0
            } else {
                textSelection.range.length = 0
            }
        }
        updateSelectionViews()
        NotificationCenter.default.post(Notification(name: Self.selectionChangedNotification, object: self))
    }
}
