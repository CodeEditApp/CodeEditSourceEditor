//
//  FoldingRibbonView.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 5/8/25.
//

import AppKit
import CodeEditTextView

extension FoldingRibbonView {
    struct DrawingFoldInfo {
        let fold: FoldRange
        let startLine: TextLineStorage<TextLine>.TextLinePosition
        let endLine: TextLineStorage<TextLine>.TextLinePosition
    }

    // MARK: - Draw

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
        let folds = getDrawingFolds(forTextRange: textRange, layoutManager: layoutManager)
        let foldCaps = FoldCapInfo(folds)
        for fold in folds.filter({ !$0.fold.isCollapsed }) {
            drawFoldMarker(
                fold,
                foldCaps: foldCaps,
                in: context,
                using: layoutManager
            )
        }

        for fold in folds.filter({ $0.fold.isCollapsed }) {
            drawFoldMarker(
                fold,
                foldCaps: foldCaps,
                in: context,
                using: layoutManager
            )
        }

        context.restoreGState()
    }

    // MARK: - Get Drawing Folds
    
    /// Generates drawable fold info for a range of text.
    ///
    /// The fold storage intentionally does not store the full ranges of all folds at each interval. We may, for an
    /// interval, find that we only receive fold information for depths > 1. In this case, we still need to draw those
    /// layers of color to create the illusion that those folds are continuous under the nested folds. To achieve this,
    /// we create 'fake' folds that span more than the queried text range. When returned for drawing, the drawing
    /// methods will draw those extra folds normally.
    ///
    /// - Parameters:
    ///   - textRange: The range of characters in text to create drawing fold info for.
    ///   - layoutManager: A layout manager to query for line layout information.
    /// - Returns: A list of folds to draw for the given text range.
    private func getDrawingFolds(
        forTextRange textRange: Range<Int>,
        layoutManager: TextLayoutManager
    ) -> [DrawingFoldInfo] {
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

        return folds.compactMap { fold in
            guard let startLine = layoutManager.textLineForOffset(fold.range.lowerBound),
                  let endLine = layoutManager.textLineForOffset(fold.range.upperBound) else {
                return nil
            }

            return DrawingFoldInfo(fold: fold, startLine: startLine, endLine: endLine)
        }
    }

    /// Draw a single fold marker for a fold.
    ///
    /// Ensure the correct fill color is set on the drawing context before calling.
    ///
    /// - Parameters:
    ///   - foldInfo: The fold to draw.
    ///   - markerContext: The context in which the fold is being drawn, including the depth and if a line is
    ///                    being hovered.
    ///   - context: The drawing context to use.
    ///   - layoutManager: A layout manager used to retrieve position information for lines.
    private func drawFoldMarker(
        _ foldInfo: DrawingFoldInfo,
        foldCaps: FoldCapInfo,
        in context: CGContext,
        using layoutManager: TextLayoutManager
    ) {
        let minYPosition = foldInfo.startLine.yPos
        let maxYPosition = foldInfo.endLine.yPos + foldInfo.endLine.height

        if foldInfo.fold.isCollapsed {
            drawCollapsedFold(minYPosition: minYPosition, maxYPosition: maxYPosition, in: context)
        } else if let hoveringFold, hoveringFold.isHoveringEqual(foldInfo.fold) {
            drawHoveredFold(
                minYPosition: minYPosition,
                maxYPosition: maxYPosition,
                in: context
            )
        } else {
            drawNestedFold(
                foldInfo: foldInfo,
                foldCaps: foldCaps,
                minYPosition: minYPosition,
                maxYPosition: maxYPosition,
                in: context
            )
        }
    }

    // MARK: - Collapsed Fold

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

        context.setStrokeColor(foldedIndicatorChevronColor)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.setLineWidth(1.3)

        context.setFillColor(foldedIndicatorColor)
        context.fill(fillRect)
        context.addPath(chevron)
        context.strokePath()

        context.restoreGState()
    }

    // MARK: - Hovered Fold

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

    // MARK: - Nested Fold

    private func drawNestedFold(
        foldInfo: DrawingFoldInfo,
        foldCaps: FoldCapInfo,
        minYPosition: CGFloat,
        maxYPosition: CGFloat,
        in context: CGContext
    ) {
        context.saveGState()
        let plainRect = foldCaps.adjustFoldRect(
            using: foldInfo,
            rect: NSRect(x: 0, y: minYPosition + 1, width: 7, height: maxYPosition - minYPosition - 2)
        )
        let radius = plainRect.width / 2.0
        let roundedRect = NSBezierPath(
            roundingRect: plainRect,
            capTop: foldCaps.foldNeedsTopCap(foldInfo),
            capBottom: foldCaps.foldNeedsBottomCap(foldInfo),
            cornerRadius: radius
        )

        context.setFillColor(markerColor)
        context.addPath(roundedRect.cgPathFallback)
        context.drawPath(using: .fill)

        // Add small white line if we're overlapping with other markers
        if foldInfo.fold.depth != 0 {
            drawOutline(
                foldInfo: foldInfo,
                foldCaps: foldCaps,
                originalPath: roundedRect.cgPathFallback,
                yPosition: minYPosition...maxYPosition,
                in: context
            )
        }

        context.restoreGState()
    }

    // MARK: - Nested Outline

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
        foldInfo: DrawingFoldInfo,
        foldCaps: FoldCapInfo,
        originalPath: CGPath,
        yPosition: ClosedRange<CGFloat>,
        in context: CGContext
    ) {
        context.saveGState()

        let plainRect = foldCaps.adjustFoldRect(
            using: foldInfo,
            rect: NSRect(
                x: -0.5,
                y: yPosition.lowerBound,
                width: frame.width + 1.0,
                height: yPosition.upperBound - yPosition.lowerBound
            )
        )
        let radius = plainRect.width / 2.0
        let roundedRect = NSBezierPath(
            roundingRect: plainRect,
            capTop: foldCaps.foldNeedsTopCap(foldInfo),
            capBottom: foldCaps.foldNeedsBottomCap(foldInfo),
            cornerRadius: radius
        )
        roundedRect.transform(using: .init(translationByX: -0.5, byY: 0.0))

        let combined = CGMutablePath()
        combined.addPath(roundedRect.cgPathFallback)
        combined.addPath(originalPath)

        context.clip(
            to: CGRect(
                x: 0,
                y: yPosition.lowerBound,
                width: 7,
                height: yPosition.upperBound - yPosition.lowerBound
            )
        )
        context.addPath(combined)
        context.setFillColor(markerBorderColor)
        context.drawPath(using: .eoFill)

        context.restoreGState()
    }
}
