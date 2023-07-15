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

    var stringRef: NSString
    var range: NSRange
    private let typesetter: Typesetter = .init()

    init(stringRef: NSString, range: NSRange) {
        self.stringRef = stringRef
        self.range = range
    }

    func prepareForDisplay(with attributes: [NSRange: Attributes], maxWidth: CGFloat) {
        let string = NSAttributedString(string: stringRef.substring(with: range))
        typesetter.prepareToTypeset(string)
        typesetter.generateLines(maxWidth: maxWidth)
    }
}
