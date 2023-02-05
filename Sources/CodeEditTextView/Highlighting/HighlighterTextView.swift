//
//  HighlighterTextView.swift
//  
//
//  Created by Khan Winter on 1/26/23.
//

import Foundation
import AppKit
import STTextView

/// The object `HighlightProviding` objects are given when asked for highlights.
public protocol HighlighterTextView {
    /// The entire range of the document.
    var documentRange: NSRange { get }
    /// A substring for the requested range.
    func stringForRange(_ nsRange: NSRange) -> String?
}

/// A default implementation for `STTextView` to be passed to `HighlightProviding` objects.
extension STTextView: HighlighterTextView {
    public var documentRange: NSRange {
        return NSRange(location: 0,
                       length: textContentStorage.textStorage?.length ?? 0)
    }

    public func stringForRange(_ nsRange: NSRange) -> String? {
        return textContentStorage.textStorage?.mutableString.substring(with: nsRange)
    }
}
