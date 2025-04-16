//
//  MinimapView+DocumentVisibleView.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 4/11/25.
//

import AppKit

extension MinimapView {
    func updateDocumentVisibleViewPosition() {
        guard let textView = textView, let editorScrollView = textView.enclosingScrollView, let layoutManager else {
            return
        }

        let availableHeight = min(minimapHeight, containerHeight)
        let scrollPercentage = editorScrollView.percentScrolled
        guard scrollPercentage.isFinite else { return }

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
            setScrollViewPosition(scrollPercentage: scrollPercentage)
        }

        layoutManager.layoutLines()
    }

    private func setScrollViewPosition(scrollPercentage: CGFloat) {
        let totalHeight = contentView.frame.height + scrollView.contentInsets.top
        let topInset = scrollView.contentInsets.top
        scrollView.contentView.scroll(
            to: NSPoint(
                x: scrollView.contentView.frame.origin.x,
                y: (
                    scrollPercentage * (totalHeight - (scrollView.documentVisibleRect.height - topInset))
                ) - topInset
            )
        )
        scrollView.reflectScrolledClipView(scrollView.contentView)
    }
}
