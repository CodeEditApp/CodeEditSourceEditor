//
//  LineFoldPlaceholder.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 5/9/25.
//

import AppKit
import CodeEditTextView

class LineFoldPlaceholder: TextAttachment {
    let fold: FoldRange
    let charWidth: CGFloat
    var isSelected: Bool = false

    init(fold: FoldRange, charWidth: CGFloat) {
        self.fold = fold
        self.charWidth = charWidth
    }

    var width: CGFloat {
        charWidth * 5
    }

    func draw(in context: CGContext, rect: NSRect) {
        context.saveGState()

        let centerY = rect.midY - 1.5

        if isSelected {
            context.setFillColor(NSColor.controlAccentColor.cgColor)
            context.addPath(
                NSBezierPath(
                    rect: rect.transform(x: 2.0, y: 3.0, width: -4.0, height: -6.0 ),
                    roundedCorners: .all,
                    cornerRadius: 2
                ).cgPathFallback
            )
            context.fillPath()
        }

        context.setFillColor(NSColor.secondaryLabelColor.cgColor)
        let size = charWidth / 2
        context.addEllipse(in: CGRect(x: rect.minX + charWidth * 1.25, y: centerY, width: size, height: size))
        context.addEllipse(in: CGRect(x: rect.minX + (charWidth * 2.25), y: centerY, width: size, height: size))
        context.addEllipse(in: CGRect(x: rect.minX + (charWidth * 3.25), y: centerY, width: size, height: size))
        context.fillPath()

        context.restoreGState()
    }
}
