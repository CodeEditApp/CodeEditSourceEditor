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
 |-> LayoutManager              Creates and manages TextLines from the text storage
 |  |-> [TextLine]              Represents a text line
 |  |   |-> Typesetter          Lays out and calculates line fragments
 |  |   |   |-> [LineFragment]  Represents a visual text line (may be multiple if text wrapping is on)
 |-> SelectionManager (depends on LayoutManager)    Maintains text selections and renders selections
 |  |-> [TextSelection]
 ```
 */
class TextView: NSView {
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
        self.layoutManager = TextLayoutManager(
            textStorage: storage,
            typingAttributes: [.font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)]
        )

        storage.delegate = storageDelegate
        storageDelegate.addDelegate(layoutManager)
        // TODO: Add Highlighter as storage delegate #2

        super.init(frame: .zero)
        wantsLayer = true
        postsFrameChangedNotifications = true
        postsBoundsChangedNotifications = true

        autoresizingMask = [.width, .height]

        frame = NSRect(
            x: 0,
            y: 0,
            width: enclosingScrollView?.documentVisibleRect.width ?? 1000,
            height: layoutManager.estimatedHeight()
        )
        print(frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: newWindow)
        guard newWindow != nil else { return }
        // Do some layout prep
        frame = NSRect(
            x: 0,
            y: 0,
            width: enclosingScrollView?.documentVisibleRect.width ?? 1000,
            height: layoutManager.estimatedHeight()
        )
    }

    // MARK: - Draw

    override open var isFlipped: Bool {
        true
    }

    override func makeBackingLayer() -> CALayer {
        let layer = CETiledLayer()
        layer.tileSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: 1000)
        layer.levelsOfDetail = 4
        layer.levelsOfDetailBias = 2
        layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        return layer
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        layoutManager.draw(inRect: dirtyRect, context: ctx)
    }

    private func updateHeightIfNeeded() {

    }
}
