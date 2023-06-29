//
//  TextView.swift
//  
//
//  Created by Khan Winter on 6/21/23.
//

import AppKit
import STTextView

class TextView: NSView {
    // MARK: - Constants

    enum LineBreakMode {
        case byCharWrapping
        case byWordWrapping
    }

    override var visibleRect: NSRect {
        if let scrollView = enclosingScrollView {
            // +200px vertically for a bit of padding
            return scrollView.visibleRect.insetBy(dx: 0, dy: 400)
        } else {
            return super.visibleRect
        }
    }

    // MARK: - Configuration

    func setString(_ string: String) {
        storage.setAttributedString(.init(string: string))
    }

    // MARK: - Objects

    private var storage: NSTextStorage!
    private var storageDelegate: MultiStorageDelegate!
    private var layoutManager: TextLayoutManager!

    // MARK: - Init

    init(string: String) {
        self.storage = NSTextStorage(string: string)
        self.storageDelegate = MultiStorageDelegate()
        self.layoutManager = TextLayoutManager(textStorage: storage)

        storage.delegate = storageDelegate
        storageDelegate.addDelegate(layoutManager)
        // TODO: Add Highlighter as storage delegate #2

        super.init(frame: .zero)
        wantsLayer = true
        postsFrameChangedNotifications = true
        postsBoundsChangedNotifications = true

        autoresizingMask = [.width, .height]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: newWindow)
        guard newWindow != nil else { return }
        layoutManager.prepareForDisplay()
    }

    // MARK: - Draw

    override open var isFlipped: Bool {
        true
    }

    override func makeBackingLayer() -> CALayer {
        let layer = CETiledLayer()
        layer.tileSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: 1000)
        layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        return layer
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.saveGState()
        ctx.setStrokeColor(NSColor.red.cgColor)
        ctx.setFillColor(NSColor.orange.cgColor)
        ctx.setLineWidth(10)
        ctx.addEllipse(in: dirtyRect)
        ctx.drawPath(using: .fillStroke)
        ctx.restoreGState()
    }
}
