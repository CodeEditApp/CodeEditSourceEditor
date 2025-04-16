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
    let scrollView: ForwardingScrollView
    /// The view text lines are rendered into.
    let contentView: FlippedNSView
    /// The box displaying the visible region on the minimap.
    let documentVisibleView: NSView

    let separatorView: NSView

    var documentVisibleViewDragGesture: NSPanGestureRecognizer?

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

    var minimapHeight: CGFloat {
        contentView.frame.height
    }

    var editorHeight: CGFloat {
        textView?.frame.height ?? 0.0
    }

    var editorToMinimapHeightRatio: CGFloat {
        minimapHeight / editorHeight
    }

    var containerHeight: CGFloat {
        (textView?.enclosingScrollView?.visibleRect.height ?? 0.0)
        - (textView?.enclosingScrollView?.contentInsets.vertical ?? 0.0)
    }

    init(textView: TextView, theme: EditorTheme) {
        self.textView = textView
        self.theme = theme
        self.lineRenderer = MinimapLineRenderer(textView: textView)

        self.scrollView = ForwardingScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.verticalScrollElasticity = .none
        scrollView.receiver = textView.enclosingScrollView

        self.contentView = FlippedNSView(frame: .zero)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        self.documentVisibleView = NSView()
        documentVisibleView.translatesAutoresizingMaskIntoConstraints = false
        documentVisibleView.wantsLayer = true
        documentVisibleView.layer?.backgroundColor = theme.text.color.withAlphaComponent(0.05).cgColor

        self.separatorView = NSView()
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.wantsLayer = true
        separatorView.layer?.backgroundColor = NSColor.separatorColor.cgColor

        super.init(frame: .zero)

        let documentVisibleViewDragGesture = NSPanGestureRecognizer(
            target: self,
            action: #selector(documentVisibleViewDragged(_:))
        )
        documentVisibleView.addGestureRecognizer(documentVisibleViewDragGesture)
        self.documentVisibleViewDragGesture = documentVisibleViewDragGesture

        addSubview(scrollView)
        addSubview(documentVisibleView)
        addSubview(separatorView)
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
            // Constrain to all sides
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),

            // Scrolling, but match width
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),

            // Y position set manually
            documentVisibleView.leadingAnchor.constraint(equalTo: leadingAnchor),
            documentVisibleView.trailingAnchor.constraint(equalTo: trailingAnchor),

            // Separator on leading side
            separatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorView.topAnchor.constraint(equalTo: topAnchor),
            separatorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            separatorView.widthAnchor.constraint(equalToConstant: 1.0)
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
            self?.updateDocumentVisibleViewPosition()
        }

        NotificationCenter.default.addObserver(
            forName: NSView.frameDidChangeNotification,
            object: editorScrollView.contentView,
            queue: .main
        ) { [weak self] _ in
            // Frame changed
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
        if documentVisibleView.frame.contains(point) {
            return documentVisibleView
        } else if visibleRect.contains(point) {
            return textView
        } else {
            return super.hitTest(point)
        }
    }

    /// Responds to a drag gesture on the document visible view. Dragging the view scrolls the editor a relative amount.
    @objc func documentVisibleViewDragged(_ sender: NSPanGestureRecognizer) {
        guard let editorScrollView = textView?.enclosingScrollView else {
            return
        }

        let translation = sender.translation(in: documentVisibleView)
        let ratio = if minimapHeight > containerHeight {
            containerHeight / (textView?.frame.height ?? 0.0)
        } else {
            editorToMinimapHeightRatio
        }
        let editorTranslation = translation.y / ratio
        sender.setTranslation(.zero, in: documentVisibleView)

        var newScrollViewY = editorScrollView.contentView.bounds.origin.y - editorTranslation
        newScrollViewY = max(-editorScrollView.contentInsets.top, newScrollViewY)
        newScrollViewY = min(
            editorScrollView.documentMaxOriginY - editorScrollView.contentInsets.top,
            newScrollViewY
        )

        editorScrollView.contentView.scroll(
            to: NSPoint(
                x: editorScrollView.contentView.bounds.origin.x,
                y: newScrollViewY
            )
        )
        editorScrollView.reflectScrolledClipView(editorScrollView.contentView)
    }
}
