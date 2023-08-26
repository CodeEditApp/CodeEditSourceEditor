//
//  TextLine.swift
//  
//
//  Created by Khan Winter on 6/21/23.
//

import Foundation
import AppKit

/// Represents a displayable line of text.
final class TextLine: Identifiable {
    let id: UUID = UUID()
//    private weak var stringRef: NSTextStorage?
    private var needsLayout: Bool = true
    var maxWidth: CGFloat?
    private(set) var typesetter: Typesetter = Typesetter()

    func setNeedsLayout() {
        needsLayout = true
        typesetter = Typesetter()
    }

    func needsLayout(maxWidth: CGFloat) -> Bool {
        needsLayout || maxWidth != self.maxWidth
    }

    func prepareForDisplay(maxWidth: CGFloat, lineHeightMultiplier: CGFloat, range: NSRange, stringRef: NSTextStorage) {
        let string = stringRef.attributedSubstring(from: range)
        self.maxWidth = maxWidth
        typesetter.prepareToTypeset(
            string,
            maxWidth: maxWidth,
            lineHeightMultiplier: lineHeightMultiplier
        )
        needsLayout = false
    }
}
