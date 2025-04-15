//
//  MinimapView+DocumentVisibleView.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 4/11/25.
//

import AppKit

extension NSScrollView {
    var percentScrolled: CGFloat {
        get {
            let currentYPos = documentVisibleRect.origin.y + contentInsets.top
            let totalHeight = (documentView?.frame.height ?? 0.0) + contentInsets.top
            let goalYPos = totalHeight - (documentVisibleRect.height - contentInsets.top)

            return currentYPos / goalYPos
        }
        set {
            let totalHeight = (documentView?.frame.height ?? 0.0) + contentInsets.top
            contentView.scroll(
                to: NSPoint(
                    x: contentView.frame.origin.x,
                    y: (newValue * (totalHeight - (documentVisibleRect.height - contentInsets.top))) - contentInsets.top
                )
            )
            reflectScrolledClipView(contentView)
        }
    }
}

extension MinimapView {
    func updateDocumentVisibleViewPosition() {
        guard let textView = textView, let editorScrollView = textView.enclosingScrollView, let layoutManager else {
            return
        }

        let minimapHeight = contentView.frame.height
        let editorHeight = textView.frame.height
        let editorToMinimapHeightRatio = minimapHeight / editorHeight

        let containerHeight = editorScrollView.visibleRect.height - editorScrollView.contentInsets.vertical
        let availableHeight = min(minimapHeight, containerHeight)
        let scrollPercentage = editorScrollView.percentScrolled

        // Update Visible Pane, should scroll down slowly as the user scrolls the document, following the scroller.
        // Visible pane's height   = scrollview visible height * (minimap line height / editor line height)
        // Visible pane's position = (container height - visible pane height) * scrollPercentage
        let visibleRectHeight = containerHeight * editorToMinimapHeightRatio
        guard visibleRectHeight < 1e100 else { return }

        let availableContainerHeight = (availableHeight - visibleRectHeight)
        let visibleRectYPos = availableContainerHeight * scrollPercentage

        documentVisibleView.frame.origin.y = scrollView.contentInsets.top + visibleRectYPos
        documentVisibleView.frame.size.height = visibleRectHeight

        // Minimap scroll offset slowly scrolls down with the visible pane.
        if minimapHeight > containerHeight {
            scrollView.percentScrolled = scrollPercentage
        }

        layoutManager.layoutLines()
    }
}
