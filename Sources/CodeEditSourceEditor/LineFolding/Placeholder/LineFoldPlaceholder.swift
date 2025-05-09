//
//  LineFoldPlaceholder.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 5/9/25.
//

import AppKit
import CodeEditTextView

class LineFoldPlaceholder: TextAttachment {
    var width: CGFloat { 17 }

    func draw(in context: CGContext, rect: NSRect) {
        context.saveGState()

        let centerY = rect.midY - 1.5

        context.setFillColor(NSColor.secondaryLabelColor.cgColor)
        context.addEllipse(in: CGRect(x: rect.minX + 2, y: centerY, width: 3, height: 3))
        context.addEllipse(in: CGRect(x: rect.minX + 7, y: centerY, width: 3, height: 3))
        context.addEllipse(in: CGRect(x: rect.minX + 12, y: centerY, width: 3, height: 3))
        context.fillPath()

        context.restoreGState()
    }
}
