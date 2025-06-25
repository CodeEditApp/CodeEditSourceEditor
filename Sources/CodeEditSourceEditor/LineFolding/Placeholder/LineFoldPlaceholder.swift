//
//  LineFoldPlaceholder.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 5/9/25.
//

import AppKit
import CodeEditTextView

protocol LineFoldPlaceholderDelegate: AnyObject {
    func placeholderDiscarded(fold: FoldRange)
}

class LineFoldPlaceholder: TextAttachment {
    let fold: FoldRange
    let charWidth: CGFloat
    var isSelected: Bool = false
    weak var delegate: LineFoldPlaceholderDelegate?

    init(delegate: LineFoldPlaceholderDelegate?, fold: FoldRange, charWidth: CGFloat) {
        self.fold = fold
        self.delegate = delegate
        self.charWidth = charWidth
    }

    var width: CGFloat {
        charWidth * 3
    }

    func draw(in context: CGContext, rect: NSRect) {
        context.saveGState()

        let size = charWidth / 3.0
        let centerY = rect.midY - (size / 2.0)

        if isSelected {
            context.setFillColor(NSColor.controlAccentColor.cgColor)
        } else {
            context.setFillColor(NSColor.tertiaryLabelColor.cgColor)
        }

        context.addPath(
            NSBezierPath(
                rect: rect.transform(x: 2.0, y: 2, width: -4.0, height: -4.0 ),
                roundedCorners: .all,
                cornerRadius: (rect.height - 4) / 2
            ).cgPathFallback
        )
        context.fillPath()

        context.setFillColor(NSColor.secondaryLabelColor.cgColor)
        context.addEllipse(in: CGRect(x: rect.minX + charWidth - (size / 2), y: centerY, width: size, height: size))
        context.addEllipse(in: CGRect(x: rect.midX - (size / 2), y: centerY, width: size, height: size))
        context.addEllipse(in: CGRect(x: rect.maxX - charWidth - (size / 2), y: centerY, width: size, height: size))
        context.fillPath()

        context.restoreGState()
    }

    func attachmentAction() -> TextAttachmentAction {
        delegate?.placeholderDiscarded(fold: fold)
        return .discard
    }
}
