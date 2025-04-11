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

    let scrollView: NSScrollView
    let contentView: FlippedNSView
    var layoutManager: TextLayoutManager?
    let lineRenderer: MinimapLineRenderer

    var theme: EditorTheme {
        didSet {
            layer?.backgroundColor = theme.background.cgColor
        }
    }

    init(textView: TextView, theme: EditorTheme) {
        self.textView = textView
        self.theme = theme
        self.lineRenderer = MinimapLineRenderer(textView: textView)

        self.scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.verticalScrollElasticity = .none

        self.contentView = FlippedNSView(frame: .zero)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        super.init(frame: .zero)

        addSubview(scrollView)
        scrollView.documentView = contentView

        self.translatesAutoresizingMaskIntoConstraints = false
        let layoutManager = TextLayoutManager(
            textStorage: textView.textStorage,
            lineHeightMultiplier: 1.0,
            wrapLines: textView.wrapLines,
            textView: contentView,
            delegate: self,
            renderDelegate: lineRenderer
        )
        self.layoutManager = layoutManager
        (textView.textStorage.delegate as? MultiStorageDelegate)?.addDelegate(layoutManager)

        wantsLayer = true
        layer?.backgroundColor = theme.background.cgColor

        setUpConstraints()
    }

    private func setUpConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),

            contentView.widthAnchor.constraint(equalTo: widthAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public var visibleRect: NSRect {
        var rect = scrollView.documentVisibleRect
        rect.origin.y += scrollView.contentInsets.top
        return rect.pixelAligned
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

    override func hitTest(_ point: NSPoint) -> NSView? {
        if visibleRect.contains(point) {
            return self
        } else {
            return super.hitTest(point)
        }
    }
}
