//
//  TextSelectionManager.swift
//  
//
//  Created by Khan Winter on 7/17/23.
//

import AppKit

protocol TextSelectionManagerDelegate: AnyObject {
    var font: NSFont { get }
    var lineHeight: CGFloat { get }

    func addCursorView(_ view: NSView)
}

/// Manages an array of text selections representing cursors (0-length ranges) and selections (>0-length ranges).
///
/// Draws selections using a draw method similar to the `TextLayoutManager` class, and adds
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

    private(set) var markedText: [MarkedText] = []
    private(set) var textSelections: [TextSelection] = []
    private unowned var layoutManager: TextLayoutManager
    private weak var delegate: TextSelectionManagerDelegate?

    init(layoutManager: TextLayoutManager, delegate: TextSelectionManagerDelegate?) {
        self.layoutManager = layoutManager
        self.delegate = delegate
        textSelections = [
            TextSelection(range: NSRange(location: 0, length: 0))
        ]
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
        for textSelection in textSelections {
            if textSelection.range.length == 0 {
                textSelection.view?.removeFromSuperview()
                let selectionView = CursorView()
                selectionView.frame.origin = layoutManager.positionForOffset(textSelection.range.location) ?? .zero
                selectionView.frame.size.height = (delegate?.font.lineHeight ?? 0) * (delegate?.lineHeight ?? 0)
                delegate?.addCursorView(selectionView)
                textSelection.view = selectionView
            } else {
                // TODO: Selection Highlights
            }
        }
    }
}
