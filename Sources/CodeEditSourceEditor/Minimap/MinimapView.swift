//
//  MinimapView.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 4/10/25.
//

import AppKit
import CodeEditTextView

class MinimapView: FlippedNSView {
    weak var textView: TextView?

    /// The container scrollview for the minimap contents.
    let scrollView: NSScrollView
    /// The view text lines are rendered into.
    let contentView: FlippedNSView
    /// The box displaying the visible region on the minimap.
    let documentVisibleView: NSView

    /// The layout manager that uses the ``lineRenderer`` to render and layout lines.
    var layoutManager: TextLayoutManager?
    /// A custom line renderer that lays out lines of text as 2px tall and draws contents as small lines
    /// using ``MinimapLineFragmentView``
    let lineRenderer: MinimapLineRenderer

    var theme: EditorTheme {
        didSet {
            documentVisibleView.layer?.backgroundColor = theme.text.color.withAlphaComponent(0.05).cgColor
            layer?.backgroundColor = theme.background.cgColor
        }
    }

    var visibleTextRange: NSRange? {
        guard let layoutManager = layoutManager else { return nil }
        let minY = max(visibleRect.minY, 0)
        let maxY = min(visibleRect.maxY, layoutManager.estimatedHeight())
        guard let minYLine = layoutManager.textLineForPosition(minY),
              let maxYLine = layoutManager.textLineForPosition(maxY) else {
            return nil
        }
        return NSRange(
            location: minYLine.range.location,
            length: (maxYLine.range.location - minYLine.range.location) + maxYLine.range.length
        )
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

        self.documentVisibleView = NSView()
        documentVisibleView.translatesAutoresizingMaskIntoConstraints = false
        documentVisibleView.wantsLayer = true
        documentVisibleView.layer?.backgroundColor = theme.text.color.withAlphaComponent(0.05).cgColor

        super.init(frame: .zero)

        addSubview(scrollView)
        addSubview(documentVisibleView)
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
        setUpListeners()
    }

    private func setUpConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),

            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),

            documentVisibleView.leadingAnchor.constraint(equalTo: leadingAnchor),
            documentVisibleView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    private func setUpListeners() {
        guard let editorScrollView = textView?.enclosingScrollView else { return }
        // Need to listen to:
        // - ScrollView offset changed
        // - ScrollView frame changed
        // and update the document visible box to match.
        NotificationCenter.default.addObserver(
            forName: NSView.boundsDidChangeNotification,
            object: editorScrollView.contentView,
            queue: .main
        ) { [weak self] _ in
            // Scroll changed
            self?.layoutManager?.layoutLines()
            self?.updateDocumentVisibleViewPosition()
        }

        NotificationCenter.default.addObserver(
            forName: NSView.frameDidChangeNotification,
            object: editorScrollView.contentView,
            queue: .main
        ) { [weak self] _ in
            // Frame changed
            self?.layoutManager?.layoutLines()
            self?.updateDocumentVisibleViewPosition()
        }
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

    override func hitTest(_ point: NSPoint) -> NSView? {
        if visibleRect.contains(point) {
            return self
        } else {
            return super.hitTest(point)
        }
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
