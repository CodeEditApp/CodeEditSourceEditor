//
//  FoldingRibbonView.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 5/8/25.
//

import AppKit
import CodeEditTextView

extension FoldingRibbonView {
    /// The context in which the fold is being drawn, including the depth and fold range.
    struct FoldMarkerDrawingContext {
        let range: ClosedRange<Int>
        let depth: UInt

        /// Increment the depth
        func incrementDepth() -> FoldMarkerDrawingContext {
            FoldMarkerDrawingContext(
                range: range,
                depth: depth + 1
            )
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext,
              let layoutManager = model?.controller?.textView.layoutManager else {
            return
        }

        context.saveGState()
        context.clip(to: dirtyRect)

        // Find the visible lines in the rect AppKit is asking us to draw.
        guard let rangeStart = layoutManager.textLineForPosition(dirtyRect.minY),
              let rangeEnd = layoutManager.textLineForPosition(dirtyRect.maxY) else {
            return
        }
        let textRange = rangeStart.range.location..<rangeEnd.range.upperBound

        let folds = getDrawingFolds(forTextRange: textRange)
        for fold in folds.filter({ !$0.isCollapsed }) {
            drawFoldMarker(
                fold,
                in: context,
                using: layoutManager
            )
        }

        for fold in folds.filter({ $0.isCollapsed }) {
            drawFoldMarker(
                fold,
                in: context,
                using: layoutManager
            )
        }

        context.restoreGState()
    }

    private func getDrawingFolds(forTextRange textRange: Range<Int>) -> [FoldRange] {
        var folds = model?.getFolds(in: textRange) ?? []

        // Add in some fake depths, we can draw these underneath the rest of the folds to make it look like it's
        // continuous
        if let minimumDepth = folds.min(by: { $0.depth < $1.depth })?.depth {
            for depth in (1..<minimumDepth).reversed() {
                folds.insert(
                    FoldRange(
                        id: .max,
                        depth: depth,
                        range: (textRange.lowerBound)..<(textRange.upperBound + 1),
                        isCollapsed: false
                    ),
                    at: 0
                )
            }
        }

        return folds
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
        in context: CGContext,
        using layoutManager: TextLayoutManager
    ) {
        guard let minYPosition = layoutManager.textLineForOffset(fold.range.lowerBound)?.yPos,
              let maxPosition = layoutManager.textLineForOffset(fold.range.upperBound) else {
            return
        }

        let maxYPosition = maxPosition.yPos + maxPosition.height

        if fold.isCollapsed {
            drawCollapsedFold(minYPosition: minYPosition, maxYPosition: maxYPosition, in: context)
        } else if let hoveringFold,
                    hoveringFold.depth == fold.depth,
                  NSRange(hoveringFold.range).intersection(NSRange(fold.range)) == NSRange(hoveringFold.range) {
            drawHoveredFold(
                minYPosition: minYPosition,
                maxYPosition: maxYPosition,
                in: context
            )
        } else {
            drawNestedFold(
                fold: fold,
                minYPosition: minYPosition,
                maxYPosition: maxYPosition,
                in: context
            )
        }
    }

    private func drawCollapsedFold(
        minYPosition: CGFloat,
        maxYPosition: CGFloat,
        in context: CGContext
    ) {
        context.saveGState()

        let fillRect = CGRect(x: 0, y: minYPosition, width: Self.width, height: maxYPosition - minYPosition)

        let height = 5.0
        let minX = 2.0
        let maxX = Self.width - 2.0
        let centerY = minYPosition + (maxYPosition - minYPosition)/2
        let minY = centerY - (height/2)
        let maxY = centerY + (height/2)
        let chevron = CGMutablePath()

        chevron.move(to: CGPoint(x: minX, y: minY))
        chevron.addLine(to: CGPoint(x: maxX, y: centerY))
        chevron.addLine(to: CGPoint(x: minX, y: maxY))

        context.setStrokeColor(NSColor.secondaryLabelColor.cgColor)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.setLineWidth(1.3)

        context.setFillColor(NSColor.tertiaryLabelColor.cgColor)
        context.fill(fillRect)
        context.addPath(chevron)
        context.strokePath()

        context.restoreGState()
    }

    private func drawHoveredFold(
        minYPosition: CGFloat,
        maxYPosition: CGFloat,
        in context: CGContext
    ) {
        context.saveGState()
        let plainRect = NSRect(x: -2, y: minYPosition, width: 11.0, height: maxYPosition - minYPosition)
        let roundedRect = NSBezierPath(roundedRect: plainRect, xRadius: 11.0 / 2, yRadius: 11.0 / 2)

        context.setFillColor(hoverFillColor.copy(alpha: hoverAnimationProgress) ?? hoverFillColor)
        context.setStrokeColor(hoverBorderColor.copy(alpha: hoverAnimationProgress) ?? hoverBorderColor)
        context.addPath(roundedRect.cgPathFallback)
        context.drawPath(using: .fillStroke)

        // Add the little arrows
        drawChevron(in: context, yPosition: minYPosition + 8, pointingUp: false)
        drawChevron(in: context, yPosition: maxYPosition - 8, pointingUp: true)

        context.restoreGState()
    }

    private func drawChevron(in context: CGContext, yPosition: CGFloat, pointingUp: Bool) {
        context.saveGState()
        let path = CGMutablePath()
        let chevronSize = CGSize(width: 4.0, height: 2.5)

        let center = (Self.width / 2)
        let minX = center - (chevronSize.width / 2)
        let maxX = center + (chevronSize.width / 2)

        let startY = pointingUp ? yPosition + chevronSize.height : yPosition - chevronSize.height

        context.setStrokeColor(NSColor.secondaryLabelColor.withAlphaComponent(hoverAnimationProgress).cgColor)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.setLineWidth(1.3)

        path.move(to: CGPoint(x: minX, y: startY))
        path.addLine(to: CGPoint(x: center, y: yPosition))
        path.addLine(to: CGPoint(x: maxX, y: startY))

        context.addPath(path)
        context.strokePath()
        context.restoreGState()
    }

    private func drawNestedFold(
        fold: FoldRange,
        minYPosition: CGFloat,
        maxYPosition: CGFloat,
        in context: CGContext
    ) {
        context.saveGState()
        let plainRect = NSRect(x: 0, y: minYPosition + 1, width: 7, height: maxYPosition - minYPosition - 2)
        // TODO: Draw a single horizontal line when folds are adjacent
        let roundedRect = NSBezierPath(roundedRect: plainRect, xRadius: 3.5, yRadius: 3.5)

        context.setFillColor(markerColor)
        context.addPath(roundedRect.cgPathFallback)
        context.drawPath(using: .fill)

        // Add small white line if we're overlapping with other markers
        if fold.depth != 0 {
            drawOutline(
                minYPosition: minYPosition,
                maxYPosition: maxYPosition,
                originalPath: roundedRect,
                in: context
            )
        }

        context.restoreGState()
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
