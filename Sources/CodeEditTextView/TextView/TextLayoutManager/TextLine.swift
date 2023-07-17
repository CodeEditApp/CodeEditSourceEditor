//
//  TextLine.swift
//  
//
//  Created by Khan Winter on 6/21/23.
//

import Foundation
import AppKit

/// Represents a displayable line of text.
final class TextLine {
    typealias Attributes = [NSAttributedString.Key: Any]

    unowned var stringRef: NSTextStorage
    var range: NSRange
    let typesetter: Typesetter = Typesetter()

    init(stringRef: NSTextStorage, range: NSRange) {
        self.stringRef = stringRef
        self.range = range
    }

    func prepareForDisplay(maxWidth: CGFloat) {
        typesetter.prepareToTypeset(
            stringRef.attributedSubstring(from: range),
            maxWidth: maxWidth
        )
    }
}
