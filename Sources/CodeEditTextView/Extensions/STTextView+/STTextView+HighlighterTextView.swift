//
//  STTextView+HighlighterTextView.swift
//  CodeEditTextView
//
//  Created by Khan Winter on 6/2/23.
//

import Foundation
import STTextView

/// A default implementation for `STTextView` to be passed to `HighlightProviding` objects.
extension STTextView: HighlighterTextView {
    public var documentRange: NSRange {
        return NSRange(
            location: 0,
            length: textContentStorage?.textStorage?.length ?? 0
        )
    }

    public func stringForRange(_ nsRange: NSRange) -> String? {
        return textContentStorage?.textStorage?.mutableString.substring(with: nsRange)
    }
}
