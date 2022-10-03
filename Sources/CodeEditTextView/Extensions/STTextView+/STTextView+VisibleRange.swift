//
//  STTextView+VisibleRange.swift
//  
//
//  Created by Khan Winter on 9/12/22.
//

import Foundation
import STTextView

extension STTextView {
    func textRange(for rect: CGRect) -> NSRange {
        let length = self.textContentStorage.textStorage?.length ?? 0

        guard let layoutManager = self.textContainer.layoutManager else {
            return NSRange(0..<length)
        }
        let container = self.textContainer

        let glyphRange = layoutManager.glyphRange(forBoundingRect: rect, in: container)

        return layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
    }

    var visibleTextRange: NSRange {
        return textRange(for: visibleRect)
    }
}
