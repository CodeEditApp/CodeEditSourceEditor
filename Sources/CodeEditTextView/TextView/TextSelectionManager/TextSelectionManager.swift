//
//  TextSelectionManager.swift
//  
//
//  Created by Khan Winter on 7/17/23.
//

import AppKit
import TextStory

protocol TextSelectionManagerDelegate: AnyObject {
    var font: NSFont { get }

    func setNeedsDisplay()
    func estimatedLineHeight() -> CGFloat
}

/// Manages an array of text selections representing cursors (0-length ranges) and selections (>0-length ranges).
///
/// Draws selections using a draw method similar to the `TextLayoutManager` class, and adds cursor views when
/// appropriate.
class TextSelectionManager: NSObject {
    struct MarkedText {
        let range: NSRange
        let attributedString: NSAttributedString
    }

    // MARK: - TextSelection

    class TextSelection {
        var range: NSRange
        weak var view: CursorView?

        init(range: NSRange, view: CursorView? = nil) {
            self.range = range
            self.view = view
        }

        var isCursor: Bool {
            range.length == 0
        }
    }

    enum Destination {
        case character
        case word
        case line
        /// Eg: Bottom of screen
        case container
        case document
    }

    enum Direction {
        case up
        case down
        case forward
        case backward
    }

    // MARK: - Properties

    class var selectionChangedNotification: Notification.Name {
        Notification.Name("TextSelectionManager.TextSelectionChangedNotification")
    }

    public var selectedLineBackgroundColor: NSColor = NSColor.selectedTextBackgroundColor.withSystemEffect(.disabled)

    private(set) var markedText: [MarkedText] = []
    private(set) var textSelections: [TextSelection] = []
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
        textSelections = [TextSelection(range: range)]
        updateSelectionViews()
    }

    public func setSelectedRanges(_ ranges: [NSRange]) {
        textSelections.forEach { $0.view?.removeFromSuperview() }
        textSelections = ranges.map { TextSelection(range: $0) }
        updateSelectionViews()
    }

    // MARK: - Selection Views

    internal func updateSelectionViews() {
        var didUpdate: Bool = false

        for textSelection in textSelections where textSelection.range.isEmpty {
            let lineFragment = layoutManager?
                .textLineForOffset(textSelection.range.location)?
                .data
                .typesetter
                .lineFragments
                .first
            let cursorOrigin = (layoutManager?.rectForOffset(textSelection.range.location) ?? .zero).origin
            if textSelection.view == nil
                || textSelection.view?.frame.origin != cursorOrigin
                || textSelection.view?.frame.height != lineFragment?.data.scaledHeight ?? 0 {
                textSelection.view?.removeFromSuperview()
                let cursorView = CursorView()
                cursorView.frame.origin = cursorOrigin
                cursorView.frame.size.height = lineFragment?.data.scaledHeight ?? 0
                layoutView?.addSubview(cursorView)
                textSelection.view = cursorView
                didUpdate = true
            }
        }

        if didUpdate {
            delegate?.setNeedsDisplay()
            NotificationCenter.default.post(Notification(name: Self.selectionChangedNotification))
        }
    }

    /// Notifies the selection manager of an edit and updates all selections accordingly.
    /// - Parameters:
    ///   - delta: The change in length of the document
    ///   - retainLength: Set to `true` if selections should keep their lengths after the edit.
    ///                   By default all selection lengths are set to 0 after any edit.
    func updateSelections(delta: Int, retainLength: Bool = false) {
        textSelections.forEach { $0.didInsertText(length: delta, retainLength: retainLength) }
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
                // Highlight the line
                guard let linePosition = layoutManager?.textLineForOffset(textSelection.range.location) else {
                    continue
                }
                let selectionRect = CGRect(
                    x: rect.minX,
                    y: layoutManager?.rectForOffset(linePosition.range.location)?.minY ?? linePosition.yPos,
                    width: rect.width,
                    height: linePosition.height
                )
                if selectionRect.intersects(rect) {
                    context.setFillColor(selectedLineBackgroundColor.cgColor)
                    context.fill(selectionRect)
                }
            } else {
                // TODO: Highlight Selection Ranges

//                guard let selectionPointMin = layoutManager.pointForOffset(selection.range.location),
//                      let selectionPointMax = layoutManager.pointForOffset(selection.range.max) else {
//                    continue
//                }
//                let selectionRect = NSRect(
//                    x: selectionPointMin.x,
//                    y: selectionPointMin.y,
//                    width: selectionPointMax.x - selectionPointMin.x,
//                    height: selectionPointMax.y - selectionPointMin.y
//                )
//                if selectionRect.intersects(rect) {
//                    // This selection has some portion in the visible rect, draw it.
//                    for linePosition in layoutManager.lineStorage.linesInRange(selection.range) {
//
//                    }
//                }
            }
        }
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
    func textStorage(
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
    }
}
