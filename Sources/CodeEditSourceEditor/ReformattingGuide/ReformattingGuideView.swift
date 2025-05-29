//
//  ReformattingGuideView.swift
//  CodeEditSourceEditor
//
//  Created by Austin Condiff on 4/28/25.
//

import AppKit
import CodeEditTextView

class ReformattingGuideView: NSView {
    private var column: Int
    private var _isVisible: Bool
    private var theme: EditorTheme

    var isVisible: Bool {
        get { _isVisible }
        set {
            _isVisible = newValue
            isHidden = !newValue
            needsDisplay = true
        }
    }

    init(column: Int = 80, isVisible: Bool = false, theme: EditorTheme) {
        self.column = column
        self._isVisible = isVisible
        self.theme = theme
        super.init(frame: .zero)
        wantsLayer = true
        isHidden = !isVisible
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }

    // Draw the reformatting guide line and shaded area
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard isVisible else {
            return
        }

        // Determine if we should use light or dark colors based on the theme's background color
        let isLightMode = theme.background.brightnessComponent > 0.5

        // Set the line color based on the theme
        let lineColor = isLightMode ?
            NSColor.black.withAlphaComponent(0.075) :
            NSColor.white.withAlphaComponent(0.175)

        // Set the shaded area color (slightly more transparent)
        let shadedColor = isLightMode ?
            NSColor.black.withAlphaComponent(0.025) :
            NSColor.white.withAlphaComponent(0.025)

        // Draw the vertical line (accounting for inverted Y coordinate system)
        lineColor.setStroke()
        let linePath = NSBezierPath()
        linePath.move(to: NSPoint(x: frame.minX, y: frame.maxY))  // Start at top
        linePath.line(to: NSPoint(x: frame.minX, y: frame.minY))  // Draw down to bottom
        linePath.lineWidth = 1.0
        linePath.stroke()

        // Draw the shaded area to the right of the line
        shadedColor.setFill()
        let shadedRect = NSRect(
            x: frame.minX,
            y: frame.minY,
            width: frame.width,
            height: frame.height
        )
        shadedRect.fill()
    }

    func updatePosition(in textView: TextView) {
        guard isVisible else {
            return
        }

        // Calculate the x position based on the font's character width and column number
        let charWidth = textView.font.boundingRectForFont.width
        let xPosition = CGFloat(column) * charWidth / 2  // Divide by 2 to account for coordinate system

        // Get the scroll view's content size
        guard let scrollView = textView.enclosingScrollView else { return }
        let contentSize = scrollView.documentVisibleRect.size

        // Ensure we don't create an invalid frame
        let maxWidth = max(0, contentSize.width - xPosition)

        // Update the frame to be a vertical line at the specified column with a shaded area to the right
        let newFrame = NSRect(
            x: xPosition,
            y: 0,  // Start above the visible area
            width: maxWidth + 1000,
            height: contentSize.height  // Use extended height
        ).pixelAligned

        frame = newFrame
        needsDisplay = true
    }

    func setVisible(_ visible: Bool) {
        isVisible = visible
    }

    func setColumn(_ newColumn: Int) {
        column = newColumn
        needsDisplay = true
    }

    func setTheme(_ newTheme: EditorTheme) {
        theme = newTheme
        needsDisplay = true
    }
}
