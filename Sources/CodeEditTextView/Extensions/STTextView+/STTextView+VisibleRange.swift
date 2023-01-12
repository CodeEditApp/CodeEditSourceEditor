//
//  STTextView+VisibleRange.swift
//  
//
//  Created by Khan Winter on 9/12/22.
//

import Foundation
import STTextView
import AppKit

extension STTextView {
    /// A helper for calculating the visible range on the text view with some small vertical padding.
    var visibleTextRange: NSRange? {
        // This helper finds the visible rect of the text using the enclosing scroll view, then finds the nearest
        // `NSTextElement`s to those points and uses those elements to create the returned range.

        // Get visible rect
        guard let bounds = enclosingScrollView?.documentVisibleRect else {
            return textLayoutManager.documentRange.nsRange(using: textContentStorage)
        }

        // Calculate min & max points w/ a small amount of padding vertically.
        let minPoint = CGPoint(x: bounds.minX,
                               y: bounds.minY - 100)
        let maxPoint = CGPoint(x: bounds.maxX,
                               y: bounds.maxY + 100)

        // Get text fragments for both the min and max points
        guard let start = textLayoutManager.textLayoutFragment(for: minPoint)?.rangeInElement.location,
              let end = textLayoutManager.textLayoutFragment(for: maxPoint)?.rangeInElement.endLocation else {
            return textLayoutManager.documentRange.nsRange(using: textContentStorage)
        }

        // Calculate a range and return it as an `NSRange`
        return NSTextRange(location: start, end: end)?.nsRange(using: textContentStorage)
    }
}
