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
    /// A helper for calculating the visible range on the text view with some small padding.
    var visibleTextRange: NSRange? {
        guard let textContentStorage = textContentStorage,
              var range = textLayoutManager
            .textViewportLayoutController
            .viewportRange?
            .nsRange(using: textContentStorage) else {
            return nil
        }
        range.location = max(range.location - 2500, 0)
        range.length = min(range.length + 2500, textContentStorage.length)
        return range
    }
}
