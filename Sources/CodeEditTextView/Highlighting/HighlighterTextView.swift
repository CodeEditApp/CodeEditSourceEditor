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
public protocol HighlighterTextView: AnyObject {
    /// The entire range of the document.
    var documentRange: NSRange { get }
    /// A substring for the requested range.
    func stringForRange(_ nsRange: NSRange) -> String?
}
