//
//  TextSelectionManager.swift
//  
//
//  Created by Khan Winter on 7/17/23.
//

import AppKit

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
        weak var layer: CALayer?

        init(range: NSRange, layer: CALayer? = nil) {
            self.range = range
            self.layer = layer
        }

        var isCursor: Bool {
            range.length == 0
        }
    }

    private(set) var markedText: [MarkedText] = []
    private(set) var textSelections: [TextSelection] = []
    private unowned var layoutManager: TextLayoutManager

    init(layoutManager: TextLayoutManager) {
        self.layoutManager = layoutManager
        textSelections = [
            TextSelection(range: NSRange(location: 0, length: 0))
        ]
//        updateSelectionLayers()
    }

    public func setSelectedRange(_ range: NSRange) {
        textSelections = [TextSelection(range: range)]
//        updateSelectionLayers()
        layoutManager.delegate?.textLayoutSetNeedsDisplay()
    }

    public func setSelectedRanges(_ ranges: [NSRange]) {
        textSelections = ranges.map { TextSelection(range: $0) }
//        updateSelectionLayers()
        layoutManager.delegate?.textLayoutSetNeedsDisplay()
    }

    /// Updates all cursor layers.
//    private func updateSelectionLayers() {
//        for textSelection in textSelections {
//            if textSelection.isCursor {
//                textSelection.layer?.removeFromSuperlayer()
////                let rect =
////                let layer = CursorLayer(rect: <#T##NSRect#>)
//            }
//        }
//    }

    // MARK: - Draw

    /// Draws all visible highlight rects.
//    internal func draw(inRect rect: CGRect, context: CGContext) {
//
//    }
}
