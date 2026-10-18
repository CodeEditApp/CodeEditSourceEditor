//
//  GitChangeIndicatorView.swift
//  CodeEditSourceEditor
//
//  Created by Abe Malla on 4/10/26.
//

import AppKit
import CodeEditTextView

// swiftlint:disable type_body_length

/// Displays git change indicators in the gutter, positioned to the left of line numbers.
///
/// This view draws colored bars/dots aligned with text lines to indicate added, modified, and deleted regions.
/// On hover, the indicator thickens and horizontal rules appear at the top and bottom of the hovered change block.
public final class GitChangeIndicatorView: NSView {
    // MARK: - Constants

    /// The width of the indicator bar in its normal (non-hovered) state.
    static let barWidth: CGFloat = 4.0

    /// The width of the indicator bar when hovered.
    static let barWidthHovered: CGFloat = 5.5

    /// Width of the git change indicator column in the gutter.
    static let totalWidth: CGFloat = 14.0

    /// The diameter of the deleted-line dot indicator.
    static let dotDiameter: CGFloat = 4.5

    /// The diameter of the deleted-line dot when hovered.
    static let dotDiameterHovered: CGFloat = 6.5

    /// Duration of the hover animation in seconds.
    private static let animationDuration: TimeInterval = 0.12

    /// Frames per second for the hover animation timer.
    private static let animationFPS: TimeInterval = 1.0 / 60.0

    // MARK: - Properties

    private weak var textView: TextView?

    /// The current set of gutter changes to render. Setting this triggers a redraw
    /// and revalidates any active hover overlay.
    var changes: [GutterChange] = [] {
        didSet {
            needsDisplay = true
            revalidateHover()
        }
    }

    // MARK: - Theme Colors

    @Invalidating(.display)
    var addedColor: NSColor = NSColor(
        light: NSColor(srgbRed: 0.267, green: 0.690, blue: 0.345, alpha: 1.0),
        dark: NSColor(srgbRed: 0.267, green: 0.690, blue: 0.345, alpha: 1.0)
    )

    @Invalidating(.display)
    var modifiedColor: NSColor = NSColor(
        light: NSColor(srgbRed: 0.196, green: 0.533, blue: 0.886, alpha: 1.0),
        dark: NSColor(srgbRed: 0.310, green: 0.565, blue: 0.886, alpha: 1.0)
    )

    @Invalidating(.display)
    var deletedColor: NSColor = NSColor(
        light: NSColor(srgbRed: 0.196, green: 0.533, blue: 0.886, alpha: 1.0),
        dark: NSColor(srgbRed: 0.310, green: 0.565, blue: 0.886, alpha: 1.0)
    )

    // MARK: - Hover State

    /// The change currently being rendered (remains set during the reverse/exit animation).
    private var hoverChange: GutterChange?

    /// Animation progress: 0.0 = fully un-hovered, 1.0 = fully hovered.
    private var hoverProgress: CGFloat = 0.0

    /// The repeating timer driving the forward or reverse animation.
    private var hoverTimer: Timer?

    /// The overlay layer used to draw horizontal rules spanning the full editor width.
    private var hoverOverlayLayer: CALayer?

    /// The overlay layer that draws horizontal rules across the gutter area (above the gutter background).
    /// This layer is added to self.layer; because `clipsToBounds = false` it can extend beyond the indicator
    /// view's bounds into the line-number/folding-ribbon area, clipped only at the GutterView's bounds.
    private var hoverGutterOverlayLayer: CALayer?

    // MARK: - NSView Overrides

    override public var isFlipped: Bool { true }

    // MARK: - Initialization

    init(textView: TextView?) {
        self.textView = textView
        super.init(frame: .zero)
        wantsLayer = true
        layerContentsRedrawPolicy = .onSetNeedsDisplay
        clipsToBounds = false
        setupTrackingArea()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        hoverTimer?.invalidate()
        hoverOverlayLayer?.removeFromSuperlayer()
        hoverGutterOverlayLayer?.removeFromSuperlayer()
    }

    // MARK: - Tracking Area

    private var currentTrackingArea: NSTrackingArea?

    private func setupTrackingArea() {
        if let existing = currentTrackingArea {
            removeTrackingArea(existing)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseMoved, .mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        currentTrackingArea = area
    }

    override public func updateTrackingAreas() {
        super.updateTrackingAreas()
        setupTrackingArea()
    }

    override public func resetCursorRects() {
        addCursorRect(bounds, cursor: .arrow)
    }

    // MARK: - Drawing

    override public func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext,
              let textView else { return }

        context.saveGState()

        // Widen the dirty rect to account for view zone whitespace that pushes indicators downward
        // during fold animations. Without this, bars offset by a view zone may be outside the original
        // dirty rect and get clipped away.
        let totalZoneHeight = textView.layoutManager?.viewZones.totalHeight ?? 0
        let widened = dirtyRect.insetBy(dx: 0, dy: -totalZoneHeight)
        context.clip(to: widened)

        // Center the bar horizontally within the indicator column.
        let centerX = frame.width / 2.0

        for change in changes {
            let barInfo = barRect(for: change, centerX: centerX, textView: textView)
            guard let barInfo, barInfo.rect.intersects(widened) else { continue }

            let isHovered = hoverChange == change
            let progress = isHovered ? hoverProgress : 0.0

            let color: NSColor
            switch change.type {
            case .added:
                color = addedColor
            case .modified:
                color = modifiedColor
            case .deleted:
                color = deletedColor
            }

            context.setFillColor(color.withAlphaComponent(0.5).cgColor)

            switch change.type {
            case .added, .modified:
                drawBar(
                    context: context,
                    rect: barInfo.rect,
                    progress: progress,
                    centerX: centerX,
                    outlineColor: color.cgColor,
                )
            case .deleted:
                // Position the dot at the top of the line (the boundary where content was deleted)
                drawDot(
                    context: context,
                    centerY: barInfo.rect.minY,
                    centerX: centerX,
                    progress: progress,
                    outlineColor: color.cgColor
                )
            }
        }

        context.restoreGState()
    }

    /// Information about a change's visual rect in the view.
    private struct BarInfo {
        let rect: NSRect
    }

    /// Computes the visual rect for a change indicator.
    private func barRect(
        for change: GutterChange,
        centerX: CGFloat,
        textView: TextView
    ) -> BarInfo? {
        let lineRange = change.lineRange
        guard !lineRange.isEmpty else { return nil }

        let firstLineIndex = lineRange.lowerBound
        let lastLineIndex = lineRange.upperBound - 1

        guard let firstLine = textView.layoutManager.textLineForIndex(firstLineIndex),
              let lastLine = textView.layoutManager.textLineForIndex(lastLineIndex) else {
            return nil
        }

        // Add view zone whitespace so git indicators slide in lockstep with line numbers
        // and text content when a zone shrinks/grows during a fold animation.
        let viewZones = textView.layoutManager.viewZones
        let hasViewZones = !viewZones.zones.isEmpty
        let firstWhitespace = hasViewZones
            ? viewZones.whitespaceHeightBeforeLine(firstLineIndex) : 0
        let lastWhitespace = hasViewZones
            ? viewZones.whitespaceHeightBeforeLine(lastLineIndex) : 0

        let topY = firstLine.yPos + firstWhitespace
        let bottomY = lastLine.yPos + lastWhitespace + lastLine.height

        let barW: CGFloat
        switch change.type {
        case .added, .modified:
            barW = Self.barWidth
        case .deleted:
            barW = Self.dotDiameter
        }

        let rect = NSRect(
            x: centerX - barW / 2.0,
            y: topY,
            width: barW,
            height: max(bottomY - topY, 1.0)
        )

        return BarInfo(rect: rect)
    }

    /// Draws a vertical bar indicator (for added/modified changes) with a subtle outline.
    private func drawBar(
        context: CGContext,
        rect: NSRect,
        progress: CGFloat,
        centerX: CGFloat,
        outlineColor: CGColor
    ) {
        let normalWidth = Self.barWidth
        let hoveredWidth = Self.barWidthHovered
        let currentWidth = normalWidth + (hoveredWidth - normalWidth) * progress

        let adjustedRect = NSRect(
            x: centerX - currentWidth / 2.0,
            y: rect.minY,
            width: currentWidth,
            height: rect.height
        )

        let cornerRadius = currentWidth / 2.0
        let path = CGPath(roundedRect: adjustedRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

        // Fill
        context.addPath(path)
        context.fillPath()

        // Subtle lighter outline
        context.setStrokeColor(outlineColor)
        context.setLineWidth(1.0)
        context.addPath(path)
        context.strokePath()
    }

    /// Draws a dot indicator (for deleted lines) with a subtle outline.
    private func drawDot(
        context: CGContext,
        centerY: CGFloat,
        centerX: CGFloat,
        progress: CGFloat,
        outlineColor: CGColor
    ) {
        let normalDiameter = Self.dotDiameter
        let hoveredDiameter = Self.dotDiameterHovered
        let currentDiameter = normalDiameter + (hoveredDiameter - normalDiameter) * progress

        let dotRect = NSRect(
            x: centerX - currentDiameter / 2.0,
            y: centerY - currentDiameter / 2.0,
            width: currentDiameter,
            height: currentDiameter
        )

        // Fill
        context.fillEllipse(in: dotRect)

        // Subtle lighter outline
        context.setStrokeColor(outlineColor)
        context.setLineWidth(0.75)
        context.strokeEllipse(in: dotRect)
    }

    // MARK: - Hover Overlay

    /// Updates the hover overlay to show/hide horizontal rules and tinted background around the hovered change.
    ///
    /// Two overlay layers are required because the GutterView clips its own sublayer tree
    /// (`layer.masksToBounds = true`), so a single layer cannot span both the gutter and text areas:
    /// - `hoverGutterOverlayLayer`: sublayer of `self.layer` — draws above the gutter background,
    ///   from the bar's left edge to where that background ends. Past it the text overlay shows through.
    /// - `hoverOverlayLayer`: sublayer of the document view's layer — covers the full text content area.
    ///   The portion behind the opaque gutter is hidden so only the text-area portion is visible.
    /// Both layers share the same drawing logic via ``configureOverlayLayer``.
    private func updateHoverOverlay() {
        guard let change = hoverChange, hoverProgress > 0 else {
            hoverGutterOverlayLayer?.removeFromSuperlayer()
            hoverGutterOverlayLayer = nil
            hoverOverlayLayer?.removeFromSuperlayer()
            hoverOverlayLayer = nil
            return
        }

        guard let textView,
              let scrollView = textView.enclosingScrollView,
              let gutterView = superview else { return }

        let centerX = frame.width / 2.0
        guard let barInfo = barRect(for: change, centerX: centerX, textView: textView) else { return }

        let ruleThickness: CGFloat = 1.0
        let topY = barInfo.rect.minY - (ruleThickness / 2.0)
        let bottomY = barInfo.rect.maxY + (ruleThickness / 2.0)
        let color: NSColor
        switch change.type {
        case .added:             color = addedColor
        case .modified, .deleted: color = modifiedColor
        }

        // Gutter overlay: from the bar's left edge to where the gutter's background ends.
        let barLeftEdge = centerX - Self.barWidth / 2.0 + 1.0
        let backgroundMaxX = (gutterView as? GutterView)?.backgroundMaxX ?? gutterView.frame.width
        let gutterOverlayWidth = backgroundMaxX - barLeftEdge
        if hoverGutterOverlayLayer == nil {
            let layer = makeOverlayLayer()
            self.layer?.addSublayer(layer)
            hoverGutterOverlayLayer = layer
        }
        if let gutterOverlay = hoverGutterOverlayLayer {
            configureOverlayLayer(
                gutterOverlay, change: change,
                topY: topY, bottomY: bottomY,
                originX: barLeftEdge, width: gutterOverlayWidth,
                ruleThickness: ruleThickness, color: color
            )
        }

        // Text overlay: full width of the document view.
        let documentView = scrollView.documentView ?? textView
        let documentWidth = documentView.frame.width
        if hoverOverlayLayer == nil {
            let layer = makeOverlayLayer()
            documentView.layer?.addSublayer(layer)
            hoverOverlayLayer = layer
        }
        if let textOverlay = hoverOverlayLayer {
            configureOverlayLayer(
                textOverlay, change: change,
                topY: topY, bottomY: bottomY,
                originX: 0, width: documentWidth,
                ruleThickness: ruleThickness, color: color
            )
        }
    }

    /// Returns a new CALayer for use as a hover overlay container.
    private func makeOverlayLayer() -> CALayer {
        let layer = CALayer()
        layer.zPosition = 100
        layer.actions = ["position": NSNull(), "bounds": NSNull(), "sublayers": NSNull(), "backgroundColor": NSNull()]
        return layer
    }

    /// Populates an overlay container layer with a tinted background fill and border rules.
    ///
    /// For `.deleted` changes, draws a single hairline rule at the deletion boundary.
    /// For `.added`/`.modified` changes, draws a semi-transparent tinted fill bounded by
    /// two hairline rules.
    private func configureOverlayLayer(
        _ container: CALayer,
        change: GutterChange,
        topY: CGFloat,
        bottomY: CGFloat,
        originX: CGFloat,
        width: CGFloat,
        ruleThickness: CGFloat,
        color: NSColor
    ) {
        container.sublayers?.forEach { $0.removeFromSuperlayer() }

        if change.type == .deleted {
            // Single hairline at the deletion boundary
            container.frame = CGRect(
                x: originX, y: topY - ruleThickness / 2.0,
                width: width, height: ruleThickness
            )
            let rule = CALayer()
            rule.backgroundColor = color.cgColor
            rule.frame = CGRect(x: 0, y: 0, width: width, height: ruleThickness)
            container.addSublayer(rule)
        } else {
            let height = bottomY - topY
            container.frame = CGRect(x: originX, y: topY, width: width, height: height)

            // Tinted background fill between the rules
            let background = CALayer()
            background.backgroundColor = color.withAlphaComponent(0.02).cgColor
            background.frame = CGRect(x: 0, y: 0, width: width, height: height)
            container.addSublayer(background)

            // Top border rule
            let topRule = CALayer()
            topRule.backgroundColor = color.cgColor
            topRule.frame = CGRect(x: 0, y: 0, width: width, height: ruleThickness)
            container.addSublayer(topRule)

            // Bottom border rule
            let bottomRule = CALayer()
            bottomRule.backgroundColor = color.cgColor
            bottomRule.frame = CGRect(x: 0, y: height - ruleThickness, width: width, height: ruleThickness)
            container.addSublayer(bottomRule)
        }
    }

    // MARK: - Mouse Events

    override public func mouseMoved(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        updateHoverForPoint(point)
    }

    override public func mouseExited(with event: NSEvent) {
        clearHover()
    }

    override public func scrollWheel(with event: NSEvent) {
        super.scrollWheel(with: event)
        // Re-evaluate hover after scroll
        let point = convert(event.locationInWindow, from: nil)
        updateHoverForPoint(point)
    }

    /// Determines which change (if any) the mouse is hovering over and updates the hover state.
    private func updateHoverForPoint(_ point: NSPoint) {
        guard let textView else {
            clearHover()
            return
        }

        let centerX = frame.width / 2.0

        // Find which change the y position falls within
        for change in changes {
            guard let barInfo = barRect(for: change, centerX: centerX, textView: textView) else { continue }

            // Expand hit-test rect to make it easier to hover (full width of the view, generous vertical padding)
            let hitRect = NSRect(
                x: 0,
                y: barInfo.rect.minY - 2,
                width: frame.width,
                height: barInfo.rect.height + 4
            )

            if hitRect.contains(point) {
                if hoverChange != change {
                    setHoveredChange(change)
                }
                return
            }
        }

        clearHover()
    }

    /// Sets the currently hovered change and starts the forward (enter) animation.
    private func setHoveredChange(_ change: GutterChange) {
        hoverTimer?.invalidate()

        // Switching to a different change: snap progress to zero and start fresh.
        if hoverChange != change {
            hoverProgress = 0.0
            hoverChange = change
            needsDisplay = true
        }

        guard hoverProgress < 1.0 else { return }

        let startProgress = hoverProgress
        let startTime = CACurrentMediaTime()
        let totalDuration = Self.animationDuration

        hoverTimer = Timer.scheduledTimer(withTimeInterval: Self.animationFPS, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            let elapsed = CACurrentMediaTime() - startTime
            let newProgress = min(startProgress + CGFloat(elapsed / totalDuration), 1.0)
            self.hoverProgress = newProgress
            self.needsDisplay = true
            self.updateHoverOverlay()
            if newProgress >= 1.0 { timer.invalidate() }
        }
    }

    /// Starts the reverse (exit) animation, decrementing progress back to zero.
    /// The hovered change reference is kept until progress reaches zero so the
    /// bar animates back before disappearing.
    private func clearHover() {
        hoverTimer?.invalidate()

        guard hoverProgress > 0 else {
            hoverChange = nil
            needsDisplay = true
            updateHoverOverlay()
            return
        }

        let startProgress = hoverProgress
        let startTime = CACurrentMediaTime()
        // Reverse duration proportional to how much of the animation is left,
        // so the bar always exits at the same visual speed it entered.
        let reverseDuration = Self.animationDuration * Double(startProgress)

        hoverTimer = Timer.scheduledTimer(withTimeInterval: Self.animationFPS, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            let elapsed = CACurrentMediaTime() - startTime
            let newProgress = max(startProgress - CGFloat(elapsed / reverseDuration), 0.0)
            self.hoverProgress = newProgress
            self.needsDisplay = true
            self.updateHoverOverlay()
            if newProgress <= 0 {
                timer.invalidate()
                self.hoverChange = nil
            }
        }
    }

    /// Re-evaluates the hover state after the `changes` array is updated.
    /// Rather than trying to match the old change by identity, we re-run hit
    /// testing at the current mouse location. This handles changes that grew,
    /// shrank, split, or merged while the cursor stayed in place.
    private func revalidateHover() {
        guard hoverChange != nil else { return }

        // Get current mouse position in our coordinate space
        guard let window, let mouseScreenPoint = NSApp.currentEvent?.locationInWindow ?? Optional(window.mouseLocationOutsideOfEventStream) else {
            return
        }
        let localPoint = convert(mouseScreenPoint, from: nil)

        // If mouse is outside our bounds, clear hover
        guard bounds.contains(localPoint) else {
            hoverTimer?.invalidate()
            hoverProgress = 0
            hoverChange = nil
            needsDisplay = true
            updateHoverOverlay()
            return
        }

        // Re-run hit testing — updateHoverForPoint will set/clear hover as appropriate
        updateHoverForPoint(localPoint)
    }
}
