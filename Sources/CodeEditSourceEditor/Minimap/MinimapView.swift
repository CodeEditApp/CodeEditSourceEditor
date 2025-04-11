//
//  MinimapView.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 4/10/25.
//

import AppKit
import CodeEditTextView

class MinimapView: NSView {
    weak var textView: TextView?
    var layoutManager: TextLayoutManager?
    let lineRenderer: MinimapLineRenderer

    var theme: EditorTheme {
        didSet {
            layer?.backgroundColor = theme.background.cgColor
        }
    }

    override var isFlipped: Bool { true }

    init(textView: TextView, theme: EditorTheme) {
        self.textView = textView
        self.theme = theme
        self.lineRenderer = MinimapLineRenderer(textView: textView)

        super.init(frame: .zero)

        self.translatesAutoresizingMaskIntoConstraints = false
        let layoutManager = TextLayoutManager(
            textStorage: textView.textStorage,
            lineHeightMultiplier: 1.0,
            wrapLines: textView.wrapLines,
            textView: self,
            delegate: self,
            renderDelegate: lineRenderer
        )
        self.layoutManager = layoutManager
        (textView.textStorage.delegate as? MultiStorageDelegate)?.addDelegate(layoutManager)

        wantsLayer = true
        layer?.backgroundColor = theme.background.cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        layoutManager?.layoutLines()
        super.layout()
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.saveGState()

        context.setFillColor(NSColor.separatorColor.cgColor)
        context.fill([
            CGRect(x: 0, y: 0, width: 1, height: frame.height)
        ])

        context.restoreGState()
    }
}

extension MinimapView: TextLayoutManagerDelegate {
    func layoutManagerHeightDidUpdate(newHeight: CGFloat) {

    }

    func layoutManagerMaxWidthDidChange(newWidth: CGFloat) {

    }

    func layoutManagerTypingAttributes() -> [NSAttributedString.Key: Any] {
        textView?.layoutManagerTypingAttributes() ?? [:]
    }

    func textViewportSize() -> CGSize {
        self.frame.size
    }

    func layoutManagerYAdjustment(_ yAdjustment: CGFloat) {
        // TODO: Adjust things
    }
}
