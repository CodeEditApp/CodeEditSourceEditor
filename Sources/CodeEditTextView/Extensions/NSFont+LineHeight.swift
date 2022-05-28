//
//  NSFont+LineHeight.swift
//  CodeEditTextView
//
//  Created by Lukas Pistrol on 28.05.22.
//

import AppKit

public extension NSFont {
    var lineHeight: Double {
        NSLayoutManager().defaultLineHeight(for: self)
    }
}
