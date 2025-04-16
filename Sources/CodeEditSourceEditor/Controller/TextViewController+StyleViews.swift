//
//  TextViewController+StyleViews.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 7/3/24.
//

import AppKit
import CodeEditTextView

extension TextViewController {
    package func generateParagraphStyle() -> NSMutableParagraphStyle {
        // swiftlint:disable:next force_cast
        let paragraph = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraph.tabStops.removeAll()
        paragraph.defaultTabInterval = CGFloat(tabWidth) * fontCharWidth
        return paragraph
    }

    /// Style the text view.
    package func styleTextView() {
        textView.postsFrameChangedNotifications = true
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.selectionManager.selectionBackgroundColor = theme.selection
        textView.selectionManager.selectedLineBackgroundColor = getThemeBackground()
        textView.selectionManager.highlightSelectedLine = isEditable
        textView.selectionManager.insertionPointColor = theme.insertionPoint
        textView.enclosingScrollView?.backgroundColor = useThemeBackground ? theme.background : .clear
        paragraphStyle = generateParagraphStyle()
        textView.typingAttributes = attributesFor(nil)
    }

    /// Finds the preferred use theme background.
    /// - Returns: The background color to use.
    private func getThemeBackground() -> NSColor {
        if useThemeBackground {
            return theme.lineHighlight
        }

        if systemAppearance == .darkAqua {
            return NSColor.quaternaryLabelColor
        }

        return NSColor.selectedTextBackgroundColor.withSystemEffect(.disabled)
    }

    /// Style the gutter view.
    package func styleGutterView() {
        gutterView.selectedLineColor = useThemeBackground ? theme.lineHighlight : systemAppearance == .darkAqua
        ? NSColor.quaternaryLabelColor
        : NSColor.selectedTextBackgroundColor.withSystemEffect(.disabled)
        gutterView.highlightSelectedLines = isEditable
        gutterView.font = font.rulerFont
        gutterView.backgroundColor = useThemeBackground ? theme.background : .windowBackgroundColor
        if self.isEditable == false {
            gutterView.selectedLineTextColor = nil
            gutterView.selectedLineColor = .clear
        }
    }

    /// Style the scroll view.
    package func styleScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.contentView.postsFrameChangedNotifications = true
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = !wrapLines
        scrollView.scrollerStyle = .overlay
    }

    package func updateContentInsets() {
        scrollView.contentView.postsBoundsChangedNotifications = true
        if let contentInsets {
            scrollView.automaticallyAdjustsContentInsets = false
            scrollView.contentInsets = contentInsets

            minimapView.scrollView.automaticallyAdjustsContentInsets = false
            minimapView.scrollView.contentInsets.top = contentInsets.top
            minimapView.scrollView.contentInsets.bottom = contentInsets.bottom
        } else {
            scrollView.automaticallyAdjustsContentInsets = true
            minimapView.scrollView.automaticallyAdjustsContentInsets = true
        }

        scrollView.contentInsets.top += additionalTextInsets?.top ?? 0
        scrollView.contentInsets.bottom += additionalTextInsets?.bottom ?? 0
        minimapView.scrollView.contentInsets.top += additionalTextInsets?.top ?? 0
        minimapView.scrollView.contentInsets.bottom += additionalTextInsets?.bottom ?? 0

        let findInset = (findViewController?.isShowingFindPanel ?? false) ? FindPanel.height : 0
        scrollView.contentInsets.top += findInset
        minimapView.scrollView.contentInsets.top += findInset

        scrollView.reflectScrolledClipView(scrollView.contentView)
        minimapView.scrollView.reflectScrolledClipView(minimapView.scrollView.contentView)

        findViewController?.topPadding = contentInsets?.top

        gutterView.frame.origin.y = -scrollView.contentInsets.top
    }
}
