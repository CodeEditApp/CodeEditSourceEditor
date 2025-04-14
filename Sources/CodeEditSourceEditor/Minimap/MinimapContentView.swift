//
//  MinimapContentView.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 4/11/25.
//

import AppKit

final class MinimapContentView: FlippedNSView {
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
