//
//  FoldingRibbonView.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 5/6/25.
//

import Foundation
import AppKit
import CodeEditTextView

final class IndentationLineFoldProvider: LineFoldProvider {
    func foldLevelAtLine(_ lineNumber: Int, layoutManager: TextLayoutManager, textStorage: NSTextStorage) -> Int? {
        guard let linePosition = layoutManager.textLineForIndex(lineNumber),
              let indentLevel = indentLevelForPosition(linePosition, textStorage: textStorage) else {
            return nil
        }

        //        if let precedingLinePosition = layoutManager.textLineForIndex(lineNumber - 1),
        //           let precedingIndentLevel = indentLevelForPosition(precedingLinePosition, textStorage: textStorage) {
        //            if precedingIndentLevel > indentLevel {
        //                return precedingIndentLevel
        //            }
        //        }
        //
        //        if let nextLinePosition = layoutManager.textLineForIndex(lineNumber + 1),
        //           let nextIndentLevel = indentLevelForPosition(nextLinePosition, textStorage: textStorage) {
        //            if nextIndentLevel > indentLevel {
        //                return nextIndentLevel
        //            }
        //        }

        return indentLevel
    }

    private func indentLevelForPosition(
        _ position: TextLineStorage<TextLine>.TextLinePosition,
        textStorage: NSTextStorage
    ) -> Int? {
        guard let substring = textStorage.substring(from: position.range) else {
            return nil
        }

        return substring.utf16 // Keep NSString units
            .enumerated()
            .first(where: { UnicodeScalar($0.element)?.properties.isWhitespace != true })?
            .offset
    }
}

let buh = IndentationLineFoldProvider()

/// Displays the code folding ribbon in the ``GutterView``.
///
/// This view draws its contents
class FoldingRibbonView: NSView {
    static let width: CGFloat = 7.0

    private var model: LineFoldingModel
    private var hoveringLine: Int?

    @Invalidating(.display)
    var backgroundColor: NSColor = NSColor.controlBackgroundColor

    @Invalidating(.display)
    var markerColor = NSColor(name: nil) { appearance in
        return switch appearance.name {
        case .aqua:
            NSColor(deviceWhite: 0.0, alpha: 0.1)
        case .darkAqua:
            NSColor(deviceWhite: 1.0, alpha: 0.1)
        default:
            NSColor()
        }
    }.cgColor

    @Invalidating(.display)
    var markerBorderColor = NSColor(name: nil) { appearance in
        return switch appearance.name {
        case .aqua:
            NSColor(deviceWhite: 1.0, alpha: 0.4)
        case .darkAqua:
            NSColor(deviceWhite: 0.0, alpha: 0.4)
        default:
            NSColor()
        }
    }.cgColor

    override public var isFlipped: Bool {
        true
    }

    init(textView: TextView, foldProvider: LineFoldProvider?) {
        self.model = LineFoldingModel(
            textView: textView,
            foldProvider: buh
        )
        super.init(frame: .zero)
        layerContentsRedrawPolicy = .onSetNeedsDisplay
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateTrackingAreas() {
        trackingAreas.forEach(removeTrackingArea)
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseMoved, .activeInKeyWindow],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
    }

    override func mouseMoved(with event: NSEvent) {
        let pointInView = convert(event.locationInWindow, from: nil)
        hoveringLine = model.textView?.layoutManager.textLineForPosition(pointInView.y)?.index
    }

    struct FoldMarkerDrawingContext {
        let range: ClosedRange<Int>
        let depth: UInt
        let hoveringLine: Int?

        func increment() -> FoldMarkerDrawingContext {
            FoldMarkerDrawingContext(
                range: range,
                depth: depth + 1,
                hoveringLine: isHovering() ? nil : hoveringLine
            )
        }

        func isHovering() -> Bool {
            guard let hoveringLine else {
                return false
            }
            return range.contains(hoveringLine)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext,
                let layoutManager = model.textView?.layoutManager else {
            return
        }

        context.saveGState()
        context.clip(to: dirtyRect)

        // Find the visible lines in the rect AppKit is asking us to draw.
        guard let rangeStart = layoutManager.textLineForPosition(dirtyRect.minY),
              let rangeEnd = layoutManager.textLineForPosition(dirtyRect.maxY) else {
            return
        }
        let lineRange = rangeStart.index...rangeEnd.index

        context.setFillColor(markerColor)
        let folds = model.getFolds(in: lineRange)
        for fold in folds {
            drawFoldMarker(
                fold,
                markerContext: FoldMarkerDrawingContext(range: lineRange, depth: 0, hoveringLine: hoveringLine),
                in: context,
                using: layoutManager
            )
        }

        context.restoreGState()
    }

    /// Draw a single fold marker for a fold.
    ///
    /// Ensure the correct fill color is set on the drawing context before calling.
    ///
    /// - Parameters:
    ///   - fold: The fold to draw.
    ///   - markerContext: The context in which the fold is being drawn, including the depth and if a line is
    ///                    being hovered.
    ///   - context: The drawing context to use.
    ///   - layoutManager: A layout manager used to retrieve position information for lines.
    private func drawFoldMarker(
        _ fold: FoldRange,
        markerContext: FoldMarkerDrawingContext,
        in context: CGContext,
        using layoutManager: TextLayoutManager
    ) {
        guard let minYPosition = layoutManager.textLineForIndex(fold.lineRange.lowerBound)?.yPos,
              let maxPosition = layoutManager.textLineForIndex(fold.lineRange.upperBound) else {
            return
        }

        let maxYPosition = maxPosition.yPos + maxPosition.height

        // TODO: Draw a single line when folds are adjacent

        if markerContext.isHovering() {
            // TODO: Handle hover state
        } else {
            let plainRect = NSRect(x: 0, y: minYPosition + 1, width: 7, height: maxYPosition - minYPosition - 2)
            let roundedRect = NSBezierPath(roundedRect: plainRect, xRadius: 3.5, yRadius: 3.5)

            context.addPath(roundedRect.cgPathFallback)
            context.drawPath(using: .fill)

            // Add small white line if we're overlapping with other markers
            if markerContext.depth != 0 {
                drawOutline(
                    minYPosition: minYPosition,
                    maxYPosition: maxYPosition,
                    originalPath: roundedRect,
                    in: context
                )
            }
        }

        // Draw subfolds
        for subFold in fold.subFolds.filter({ $0.lineRange.overlaps(markerContext.range) }) {
            drawFoldMarker(subFold, markerContext: markerContext.increment(), in: context, using: layoutManager)
        }
    }

    /// Draws a rounded outline for a rectangle, creating the small, light, outline around each fold indicator.
    ///
    /// This function does not change fill colors for the given context.
    ///
    /// - Parameters:
    ///   - minYPosition: The minimum y position of the rectangle to outline.
    ///   - maxYPosition: The maximum y position of the rectangle to outline.
    ///   - originalPath: The original bezier path for the rounded rectangle.
    ///   - context: The context to draw in.
    private func drawOutline(
        minYPosition: CGFloat,
        maxYPosition: CGFloat,
        originalPath: NSBezierPath,
        in context: CGContext
    ) {
        context.saveGState()

        let plainRect = NSRect(x: -0.5, y: minYPosition, width: 8, height: maxYPosition - minYPosition)
        let roundedRect = NSBezierPath(roundedRect: plainRect, xRadius: 4, yRadius: 4)

        let combined = CGMutablePath()
        combined.addPath(roundedRect.cgPathFallback)
        combined.addPath(originalPath.cgPathFallback)

        context.clip(to: CGRect(x: 0, y: minYPosition, width: 7, height: maxYPosition - minYPosition))
        context.addPath(combined)
        context.setFillColor(markerBorderColor)
        context.drawPath(using: .eoFill)

        context.restoreGState()
    }
}
