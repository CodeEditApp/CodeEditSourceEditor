//
//  MinimapView+DocumentVisibleView.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 4/11/25.
//

import AppKit

extension MinimapView {
    func updateDocumentVisibleViewPosition() {
        guard let textView = textView, let editorScrollView = textView.enclosingScrollView else { return }
        layoutManager?.layoutLines(in: scrollView.documentVisibleRect)
        let editorHeight = textView.frame.height
        let minimapHeight = contentView.frame.height

        let containerHeight = scrollView.documentVisibleRect.height
        let scrollPercentage = (
            editorScrollView.documentVisibleRect.origin.y + editorScrollView.contentInsets.top
        ) / textView.frame.height
//        let scrollOffset = editorScrollView.documentVisibleRect.origin.y

//        let scrollMultiplier: CGFloat = if minimapHeight < containerHeight {
//            1.0
//        } else {
//            1.0 - (minimapHeight - containerHeight) / (editorHeight - containerHeight)
//        }

        let newMinimapOrigin = minimapHeight * scrollPercentage
        scrollView.contentView.bounds.origin.y = newMinimapOrigin - editorScrollView.contentInsets.top
    }
}
