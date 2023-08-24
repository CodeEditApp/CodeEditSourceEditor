//
//  TextSelectionManager.swift
//  
//
//  Created by Khan Winter on 7/17/23.
//

import AppKit

protocol TextSelectionManagerDelegate: AnyObject {
    var font: NSFont { get }

    func setNeedsDisplay()
    func estimatedLineHeight() -> CGFloat
}

/// Manages an array of text selections representing cursors (0-length ranges) and selections (>0-length ranges).
///
/// Draws selections using a draw method similar to the `TextLayoutManager` class, and adds cursor views when
/// appropriate.
class TextSelectionManager {
    struct MarkedText {
        let range: NSRange
        let attributedString: NSAttributedString
    }

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

        func didInsertText(length: Int) {
            range.length = 0
            range.location += length
        }
    }

    class var selectionChangedNotification: Notification.Name {
        Notification.Name("TextSelectionManager.TextSelectionChangedNotification")
    }

    public var selectedLineBackgroundColor: NSColor = NSColor.selectedTextBackgroundColor.withSystemEffect(.disabled)

    private(set) var markedText: [MarkedText] = []
    private(set) var textSelections: [TextSelection] = []
    private weak var layoutManager: TextLayoutManager?
    weak private var layoutView: NSView?
    private weak var delegate: TextSelectionManagerDelegate?

    init(layoutManager: TextLayoutManager, layoutView: NSView?, delegate: TextSelectionManagerDelegate?) {
        self.layoutManager = layoutManager
        self.layoutView = layoutView
        self.delegate = delegate
        textSelections = []
        updateSelectionViews()
    }

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

    internal func updateSelectionViews() {
        textSelections.forEach { $0.view?.removeFromSuperview() }
        for textSelection in textSelections where textSelection.range.isEmpty {
            textSelection.view?.removeFromSuperview()
            let lineFragment = layoutManager?
                .textLineForOffset(textSelection.range.location)?
                .data
                .typesetter
                .lineFragments
                .first

            let cursorView = CursorView()
            cursorView.frame.origin = (layoutManager?.rectForOffset(textSelection.range.location) ?? .zero).origin

            cursorView.frame.size.height = lineFragment?.data.scaledHeight ?? 0
            layoutView?.addSubview(cursorView)
            textSelection.view = cursorView
        }
        delegate?.setNeedsDisplay()
        NotificationCenter.default.post(Notification(name: Self.selectionChangedNotification))
    }

    internal func removeCursors() {
        for textSelection in textSelections {
            textSelection.view?.removeFromSuperview()
        }
    }

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
                context.setFillColor(selectedLineBackgroundColor.cgColor)
                context.fill(
                    CGRect(
                        x: rect.minX,
                        y: layoutManager?.rectForOffset(linePosition.range.location)?.minY ?? linePosition.yPos,
                        width: rect.width,
                        height: linePosition.height
                    )
                )
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
