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
    weak var stringRef: NSTextStorage?
    private var needsLayout: Bool = true
    var maxWidth: CGFloat?
    private(set) var typesetter: Typesetter = Typesetter()

    init(stringRef: NSTextStorage) {
        self.stringRef = stringRef
    }

    func setNeedsLayout() {
        needsLayout = true
        typesetter = Typesetter()
    }

    func needsLayout(maxWidth: CGFloat) -> Bool {
        needsLayout || maxWidth != self.maxWidth
    }

    func prepareForDisplay(maxWidth: CGFloat, lineHeightMultiplier: CGFloat, range: NSRange) {
        guard let string = stringRef?.attributedSubstring(from: range) else { return }
        self.maxWidth = maxWidth
        typesetter.prepareToTypeset(
            string,
            maxWidth: maxWidth,
            lineHeightMultiplier: lineHeightMultiplier
        )
        needsLayout = false
    }
}
