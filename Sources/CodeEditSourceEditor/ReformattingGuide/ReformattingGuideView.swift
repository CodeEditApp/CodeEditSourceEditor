import AppKit
import CodeEditTextView

class ReformattingGuideView: NSView {
    private let column: Int = 80

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        print("ReformattingGuideView initialized with frame: \(frameRect)")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        print("Drawing guide view with frame: \(frame)")

        // For debugging, make the guide more visible
        NSColor.red.withAlphaComponent(0.3).setFill()
        frame.fill()

        // Draw a border around the guide for better visibility
        NSColor.blue.setStroke()
        let borderPath = NSBezierPath(rect: frame)
        borderPath.lineWidth = 2.0
        borderPath.stroke()

        // Get the current theme's background color to determine if we're in light or dark mode
        let isLightMode = NSApp.effectiveAppearance.name == .aqua

        // Set the line color based on the theme
        let lineColor = isLightMode ?
            NSColor.black.withAlphaComponent(0.1) :
            NSColor.white.withAlphaComponent(0.1)

        // Set the shaded area color (slightly more transparent)
        let shadedColor = isLightMode ?
            NSColor.black.withAlphaComponent(0.05) :
            NSColor.white.withAlphaComponent(0.05)

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
        // Wait for the text view to have a valid width
        guard textView.frame.width > 0 else {
            print("Text view width is 0, skipping position update")
            return
        }

        // Calculate the x position based on the font's character width and column number
        let charWidth = textView.font.boundingRectForFont.width
        let xPosition = CGFloat(column) * charWidth

        print("Updating guide position:")
        print("- Character width: \(charWidth)")
        print("- Target column: \(column)")
        print("- Calculated x position: \(xPosition)")
        print("- Text view width: \(textView.frame.width)")

        // Ensure we don't create an invalid frame
        let maxWidth = max(0, textView.frame.width - xPosition/2)

        // Update the frame to be a vertical line at column 80 with a shaded area to the right
        let newFrame = NSRect(
            x: 200,
            y: 0,
            width: maxWidth,
            height: textView.frame.height
        )
        print("Setting new frame: \(newFrame)")

        frame = newFrame
        needsDisplay = true
    }
}
