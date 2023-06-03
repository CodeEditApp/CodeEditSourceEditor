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
        guard let textContentStorage = textContentStorage else {
            return nil
        }

        // This helper finds the visible rect of the text using the enclosing scroll view, then finds the nearest
        // `NSTextElement`s to those points and uses those elements to create the returned range.

        // Get visible rect
        guard let bounds = enclosingScrollView?.documentVisibleRect else {
            return nil
        }

        // Calculate min & max points w/ a small amount of padding vertically.
        let minPoint = CGPoint(
            x: bounds.minX,
            y: bounds.minY - 200
        )
        let maxPoint = CGPoint(
            x: bounds.maxX,
            y: bounds.maxY + 200
        )

        // Get text fragments for both the min and max points
        guard let start = textLayoutManager.textLayoutFragment(for: minPoint)?.rangeInElement.location else {
            return nil
        }

        // End point can be tricky sometimes. If the document is smaller than the scroll view it can sometimes return
        // nil for the `maxPoint` layout fragment. So we attempt to grab the last fragment.
        var end: NSTextLocation?

        if let endFragment = textLayoutManager.textLayoutFragment(for: maxPoint) {
            end = endFragment.rangeInElement.location
        } else {
            textLayoutManager.ensureLayout(for: NSTextRange(location: textLayoutManager.documentRange.endLocation))
            textLayoutManager.enumerateTextLayoutFragments(
                from: textLayoutManager.documentRange.endLocation,
                options: [.reverse, .ensuresLayout, .ensuresExtraLineFragment]
            ) { layoutFragment in
                end = layoutFragment.rangeInElement.endLocation
                return false
            }
        }

        guard let end else { return nil }

        guard start.compare(end) != .orderedDescending else {
            return NSTextRange(location: end, end: start)?.nsRange(using: textContentStorage)
        }

        // Calculate a range and return it as an `NSRange`
        return NSTextRange(location: start, end: end)?.nsRange(using: textContentStorage)
    }
}
