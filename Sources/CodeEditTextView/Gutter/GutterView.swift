//
//  GutterView.swift
//  
//
//  Created by Khan Winter on 8/22/23.
//

import AppKit

protocol GutterViewDelegate: AnyObject {
    func gutterView(updatedWidth: CGFloat)
    func gutterViewVisibleRect() -> CGRect
}

class GutterView: NSView {
    @Invalidating(.display)
    var textColor: NSColor = .secondaryLabelColor

    @Invalidating(.display)
    var font: NSFont = .systemFont(ofSize: 13)

    weak var delegate: GutterViewDelegate?
    weak var layoutManager: TextLayoutManager?

    private var maxWidth: CGFloat = 0
    private var maxLineCount: Int = 0

    override var isFlipped: Bool {
        true
    }

    init(font: NSFont, textColor: NSColor, delegate: GutterViewDelegate?, layoutManager: TextLayoutManager?) {
        self.font = font
        self.textColor = textColor
        self.delegate = delegate
        self.layoutManager = layoutManager

        super.init(frame: .zero)
//        wantsLayer = true
//        autoresizingMask = [.width, .height]
        wantsLayer = true
        layerContentsRedrawPolicy = .onSetNeedsDisplay
        translatesAutoresizingMaskIntoConstraints = false

//        layer?.backgroundColor = NSColor.red.cgColor
//        draw(frame)
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext,
              let layoutManager,
              let delegate else {
            return
        }
        let originalMaxWidth = maxWidth
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        context.saveGState()
        context.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
        for linePosition in layoutManager.visibleLines() {
            let ctLine = CTLineCreateWithAttributedString(
                NSAttributedString(string: "\(linePosition.index + 1)", attributes: attributes)
            )
            let fragment: LineFragment? = linePosition.data.typesetter.lineFragments.first?.data
            let topDistance: CGFloat = ((fragment?.scaledHeight ?? 0) - (fragment?.height ?? 0))/2.0

            context.textPosition = CGPoint(
                x: 0,
                y: linePosition.yPos - delegate.gutterViewVisibleRect().origin.y
                + (fragment?.height ?? 0)
                - topDistance
            )
            CTLineDraw(ctLine, context)

            maxWidth = max(CTLineGetBoundsWithOptions(ctLine, CTLineBoundsOptions()).width, maxWidth)
        }
        context.restoreGState()

        if maxLineCount < layoutManager.lineStorage.count {
            let maxCtLine = CTLineCreateWithAttributedString(
                NSAttributedString(string: "\(layoutManager.lineStorage.count)", attributes: attributes)
            )
            let bounds = CTLineGetBoundsWithOptions(maxCtLine, CTLineBoundsOptions())
            maxWidth = max(maxWidth, bounds.width)
            maxLineCount = layoutManager.lineStorage.count
        }

        if originalMaxWidth != maxWidth {
            self.frame.size.width = maxWidth
            delegate.gutterView(updatedWidth: maxWidth)
        }
    }
}
