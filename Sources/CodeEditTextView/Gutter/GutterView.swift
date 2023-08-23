//
//  GutterView.swift
//  
//
//  Created by Khan Winter on 8/22/23.
//

import AppKit

class GutterView: NSView {
    struct EdgeInsets: Equatable, Hashable {
        let leading: CGFloat
        let trailing: CGFloat

        var horizontal: CGFloat {
            leading + trailing
        }
    }

    @Invalidating(.display)
    var textColor: NSColor = .secondaryLabelColor

    @Invalidating(.display)
    var font: NSFont = .systemFont(ofSize: 13)

    @Invalidating(.display)
    var edgeInsets: EdgeInsets = EdgeInsets(leading: 20, trailing: 12)

    @Invalidating(.display)
    var backgroundColor: NSColor? = NSColor.controlBackgroundColor

    @Invalidating(.display)
    var highlightSelectedLines: Bool = true

    @Invalidating(.display)
    var selectedLineColor: NSColor = NSColor.selectedTextBackgroundColor.withSystemEffect(.disabled)

    private weak var textView: TextView?
    private var maxWidth: CGFloat = 0
    /// The maximum number of digits found for a line number.
    private var maxLineLength: Int = 0

    override var isFlipped: Bool {
        true
    }

    init(
        font: NSFont,
        textColor: NSColor,
        textView: TextView
    ) {
        self.font = font
        self.textColor = textColor
        self.textView = textView

        super.init(frame: .zero)
        wantsLayer = true
        layerContentsRedrawPolicy = .onSetNeedsDisplay
        translatesAutoresizingMaskIntoConstraints = false
        layer?.masksToBounds = false

        NotificationCenter.default.addObserver(
            forName: TextSelectionManager.selectionChangedNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.needsDisplay = true
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Updates the width of the gutter if needed.
    func updateWidthIfNeeded() {
        guard let textView else { return }
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        let originalMaxWidth = maxWidth
        // Reserve at least 3 digits of space no matter what
        let lineStorageDigits = max(3, String(textView.layoutManager.lineStorage.count).count)

        if maxLineLength < lineStorageDigits {
            // Update the max width
            let maxCtLine = CTLineCreateWithAttributedString(
                NSAttributedString(string: String(repeating: "0", count: lineStorageDigits), attributes: attributes)
            )
            let bounds = CTLineGetBoundsWithOptions(maxCtLine, CTLineBoundsOptions())
            maxWidth = max(maxWidth, bounds.width)
            maxLineLength = lineStorageDigits
        }

        if originalMaxWidth != maxWidth {
            self.frame.size.width = maxWidth + edgeInsets.horizontal
            textView.layoutManager.gutterWidth = maxWidth + edgeInsets.horizontal
        }
    }

    private func drawSelectedLines(_ context: CGContext) {
        guard let textView = textView,
              let selectionManager = textView.selectionManager,
              let visibleRange = textView.visibleTextRange,
              highlightSelectedLines else {
            return
        }
        context.saveGState()
        context.setFillColor(selectedLineColor.cgColor)
        for selection in selectionManager.textSelections {
            guard let line = textView.layoutManager.textLineForOffset(selection.range.location),
                  visibleRange.intersection(line.range) != nil else {
                continue
            }
            context.fill(CGRect(x: 0.0, y: line.yPos, width: maxWidth + edgeInsets.horizontal, height: line.height))
        }
        context.restoreGState()
    }

    private func drawLineNumbers(_ context: CGContext) {
        guard let textView = textView else { return }
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]

        context.saveGState()
        context.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
        for linePosition in textView.layoutManager.visibleLines() {
            let ctLine = CTLineCreateWithAttributedString(
                NSAttributedString(string: "\(linePosition.index + 1)", attributes: attributes)
            )
            let fragment: LineFragment? = linePosition.data.typesetter.lineFragments.first?.data

            let topPadding: CGFloat = ((fragment?.scaledHeight ?? 0) - (fragment?.height ?? 0))/2.0
            let yPos = linePosition.yPos + (fragment?.height ?? 0) - topPadding
            // Leading padding + (width - linewidth)
            let xPos = edgeInsets.leading + (maxWidth - CTLineGetBoundsWithOptions(ctLine, CTLineBoundsOptions()).width)

            context.textPosition = CGPoint(
                x: xPos,
                y: yPos
            )
            CTLineDraw(ctLine, context)
        }
        context.restoreGState()
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else {
            return
        }
        layer?.backgroundColor = backgroundColor?.cgColor
        updateWidthIfNeeded()
        drawSelectedLines(context)
        drawLineNumbers(context)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
