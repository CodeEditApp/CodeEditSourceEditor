//
//  NSFont+LineHeight.swift
//  CodeEditTextView
//
//  Created by Lukas Pistrol on 28.05.22.
//

import AppKit
import CodeEditInputView

public extension NSFont {
    /// The default line height of the font.
    var lineHeight: Double {
        let string = NSAttributedString(string: "0", attributes: [.font: self])
        let typesetter = CTTypesetterCreateWithAttributedString(string)
        let ctLine = CTTypesetterCreateLine(typesetter, CFRangeMake(0, 1))
        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        var leading: CGFloat = 0
        CTLineGetTypographicBounds(ctLine, &ascent, &descent, &leading)
        return ascent + descent + leading
    }
}
