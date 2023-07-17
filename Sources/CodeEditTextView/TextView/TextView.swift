//
//  TextView.swift
//  
//
//  Created by Khan Winter on 6/21/23.
//

import AppKit
import STTextView

/**

```
 TextView
 |-> LayoutManager              Creates, manages, and renders TextLines from the text storage
 |  |-> [TextLine]              Represents a text line
 |  |   |-> Typesetter          Lays out and calculates line fragments
 |  |   |   |-> [LineFragment]  Represents a visual text line (may be multiple if text wrapping is on)
 |-> SelectionManager (depends on LayoutManager)    Maintains text selections and renders selections
 |  |-> [TextSelection]
 ```
 */
class TextView: NSView {
    // MARK: - Configuration

    func setString(_ string: String) {
        textStorage.setAttributedString(.init(string: string))
    }

    public var font: NSFont
    public var lineHeight: CGFloat
    public var wrapLines: Bool
    public var editorOverscroll: CGFloat
    public var isEditable: Bool
    public var letterSpacing: Double

    // MARK: - Internal Properties

    private(set) var textStorage: NSTextStorage!
    private(set) var layoutManager: TextLayoutManager!

    var scrollView: NSScrollView? {
        guard let enclosingScrollView, enclosingScrollView.documentView == self else { return nil }
        return enclosingScrollView
    }

    // MARK: - Init

    init(
        string: String,
        font: NSFont,
        lineHeight: CGFloat,
        wrapLines: Bool,
        editorOverscroll: CGFloat,
        isEditable: Bool,
        letterSpacing: Double,
        storageDelegate: MultiStorageDelegate!
    ) {
        self.textStorage = NSTextStorage(string: string)
        self.layoutManager = TextLayoutManager(
            textStorage: textStorage,
            typingAttributes: [
                .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular),
                .paragraphStyle: {
                    // swiftlint:disable:next force_cast
                    let paragraph = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
//                    paragraph.tabStops.removeAll()
//                    paragraph.defaultTabInterval = CGFloat(tabWidth) * fontCharWidth
                    return paragraph
                }()
            ],
            lineHeightMultiplier: lineHeight,
            wrapLines: wrapLines
        )

        self.font = font
        self.lineHeight = lineHeight
        self.wrapLines = wrapLines
        self.editorOverscroll = editorOverscroll
        self.isEditable = isEditable
        self.letterSpacing = letterSpacing

        textStorage.delegate = storageDelegate
        storageDelegate.addDelegate(layoutManager)

        super.init(frame: .zero)

        layoutManager.delegate = self

        wantsLayer = true
        postsFrameChangedNotifications = true
        postsBoundsChangedNotifications = true

        autoresizingMask = [.width, .height]

        updateFrameIfNeeded()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: newWindow)
        updateFrameIfNeeded()
    }

    override func viewDidEndLiveResize() {
        super.viewDidEndLiveResize()
        updateFrameIfNeeded()
    }

    // MARK: - Draw

    override open var isFlipped: Bool {
        true
    }

    override var visibleRect: NSRect {
        if let scrollView = scrollView {
            // +200px vertically for a bit of padding
            return scrollView.documentVisibleRect.insetBy(dx: 0, dy: -400).offsetBy(dx: 0, dy: 200)
        } else {
            return super.visibleRect
        }
    }

    var visibleTextRange: NSRange? {
        var min: Int = -1
        var max: Int = 0
        layoutManager.enumerateLines(startingAt: CGFloat.maximum(visibleRect.minY, 0)) { _, offset, height in
            if min < 0 {
                min = offset
            } else {
                max = offset
            }
            return height < visibleRect.maxY
        }
        guard min >= 0 else { return nil }
        return NSRange(location: min, length: max - min)
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        layoutManager.draw(inRect: dirtyRect, context: ctx)
    }

    public func updateFrameIfNeeded() {
        var availableSize = scrollView?.contentSize ?? .zero
        availableSize.height -= (scrollView?.contentInsets.top ?? 0) + (scrollView?.contentInsets.bottom ?? 0)
        let newHeight = layoutManager.estimatedHeight()
        let newWidth = layoutManager.estimatedWidth()

        var didUpdate = false

        if frame.size.height != availableSize.height
            || (newHeight > availableSize.height && frame.size.height != newHeight) {
            frame.size.height = max(availableSize.height, newHeight + editorOverscroll)
            didUpdate = true
        }

        if wrapLines && frame.size.width != availableSize.width {
            frame.size.width = availableSize.width
            didUpdate = true
        } else if !wrapLines && newWidth > availableSize.width && frame.size.width != newWidth {
            frame.size.width = max(newWidth, availableSize.width)
            didUpdate = true
        }

        if didUpdate {
            needsLayout = true
            needsDisplay = true
            layoutManager.invalidateLayoutForRect(frame)
        }
    }
}

// MARK: - TextLayoutManagerDelegate

extension TextView: TextLayoutManagerDelegate {
    func maxWidthDidChange(newWidth: CGFloat) {
        updateFrameIfNeeded()
    }

    func textViewportSize() -> CGSize {
        if let scrollView = scrollView {
            var size = scrollView.contentSize
            size.height -= scrollView.contentInsets.top + scrollView.contentInsets.bottom
            return size
        } else {
            return CGSize(width: CGFloat.infinity, height: CGFloat.infinity)
        }
    }

    func textLayoutSetNeedsDisplay() {
        needsDisplay = true
    }
}
