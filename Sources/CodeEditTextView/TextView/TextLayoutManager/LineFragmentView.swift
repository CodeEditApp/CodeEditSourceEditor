//
//  LineFragmentView.swift
//  
//
//  Created by Khan Winter on 8/14/23.
//

import AppKit

final class LineFragmentView: NSView {
    private weak var lineFragment: LineFragment?

    override var isFlipped: Bool {
        true
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        lineFragment = nil
    }

    public func setLineFragment(_ newFragment: LineFragment) {
        self.lineFragment = newFragment
        self.frame.size = CGSize(width: newFragment.width, height: newFragment.scaledHeight)
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let lineFragment, let context = NSGraphicsContext.current?.cgContext else {
            return
        }
        context.saveGState()
        context.textMatrix = .init(scaleX: 1, y: -1)
        context.textPosition = CGPoint(
            x: 0,
            y: lineFragment.height + ((lineFragment.height - lineFragment.scaledHeight) / 2)
        )
        CTLineDraw(lineFragment.ctLine, context)
        context.restoreGState()
    }
}
