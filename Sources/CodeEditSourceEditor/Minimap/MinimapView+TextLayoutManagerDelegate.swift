//
//  MinimapView+TextLayoutManagerDelegate.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 4/11/25.
//

import AppKit
import CodeEditTextView

extension MinimapView: TextLayoutManagerDelegate {
    func layoutManagerHeightDidUpdate(newHeight: CGFloat) {
        contentView.frame.size.height = newHeight
    }

    func layoutManagerMaxWidthDidChange(newWidth: CGFloat) { }

    func layoutManagerTypingAttributes() -> [NSAttributedString.Key: Any] {
        textView?.layoutManagerTypingAttributes() ?? [:]
    }

    func textViewportSize() -> CGSize {
        var size = scrollView.contentSize
        size.height -= scrollView.contentInsets.top + scrollView.contentInsets.bottom
        size.width = textView?.layoutManager.maxLineLayoutWidth ?? size.width
        return size
    }

    func layoutManagerYAdjustment(_ yAdjustment: CGFloat) {
        var point = scrollView.documentVisibleRect.origin
        point.y += yAdjustment
        scrollView.documentView?.scroll(point)
    }
}
