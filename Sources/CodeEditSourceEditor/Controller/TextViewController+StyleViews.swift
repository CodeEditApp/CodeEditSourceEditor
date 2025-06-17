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
        textView.selectionManager.highlightSelectedLine = config.behavior.isEditable
        textView.selectionManager.insertionPointColor = theme.insertionPoint
        textView.enclosingScrollView?.backgroundColor = if useThemeBackground {
            theme.background
        } else {
            .clear
        }
        textView.overscrollAmount = editorOverscroll
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
        gutterView.selectedLineColor = if useThemeBackground {
            theme.lineHighlight
        } else if systemAppearance == .darkAqua {
            NSColor.quaternaryLabelColor
        } else {
            NSColor.selectedTextBackgroundColor.withSystemEffect(.disabled)
        }
        gutterView.highlightSelectedLines = config.behavior.isEditable
        gutterView.font = font.rulerFont
        gutterView.backgroundColor = if useThemeBackground {
            theme.background
        } else {
            .windowBackgroundColor
        }
        if config.behavior.isEditable == false {
            gutterView.selectedLineTextColor = nil
            gutterView.selectedLineColor = .clear
        }
        gutterView.isHidden = !showGutter
    }

    /// Style the scroll view.
    package func styleScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.contentView.postsFrameChangedNotifications = true
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = !wrapLines
        scrollView.scrollerStyle = .overlay
    }

    package func styleMinimapView() {
        minimapView.postsFrameChangedNotifications = true
        minimapView.isHidden = !showMinimap
    }

    package func styleReformattingGuideView() {
        reformattingGuideView.updatePosition(in: textView)
        reformattingGuideView.isHidden = !showReformattingGuide
    }

    /// Updates all relevant content insets including the find panel, scroll view, minimap and gutter position.
    package func updateContentInsets() {
        updateTextInsets()

        scrollView.contentView.postsBoundsChangedNotifications = true
        if let contentInsets = config.layout.contentInsets {
            scrollView.automaticallyAdjustsContentInsets = false
            scrollView.contentInsets = contentInsets

            minimapView.scrollView.automaticallyAdjustsContentInsets = false
            minimapView.scrollView.contentInsets.top = contentInsets.top
            minimapView.scrollView.contentInsets.bottom = contentInsets.bottom
        } else {
            scrollView.automaticallyAdjustsContentInsets = true
            minimapView.scrollView.automaticallyAdjustsContentInsets = true
        }

        // `additionalTextInsets` only effects text content.
        let additionalTextInsets = config.layout.additionalTextInsets
        scrollView.contentInsets.top += additionalTextInsets?.top ?? 0
        scrollView.contentInsets.bottom += additionalTextInsets?.bottom ?? 0
        minimapView.scrollView.contentInsets.top += additionalTextInsets?.top ?? 0
        minimapView.scrollView.contentInsets.bottom += additionalTextInsets?.bottom ?? 0

        // Inset the top by the find panel height
        let findInset: CGFloat = if findViewController?.viewModel.isShowingFindPanel ?? false {
            findViewController?.viewModel.panelHeight ?? 0
        } else {
            0
        }
        scrollView.contentInsets.top += findInset
        minimapView.scrollView.contentInsets.top += findInset

        findViewController?.topPadding = config.layout.contentInsets?.top

        gutterView.frame.origin.y = textView.frame.origin.y - scrollView.contentInsets.top

        // Update scrollview tiling
        scrollView.reflectScrolledClipView(scrollView.contentView)
        minimapView.scrollView.reflectScrolledClipView(minimapView.scrollView.contentView)
    }

    /// Updates the text view's text insets. See ``textViewInsets`` for calculation.
    func updateTextInsets() {
        // Allow this method to be called before ``loadView()``
        guard textView != nil, minimapView != nil else { return }
        if textView.textInsets != textViewInsets {
            textView.textInsets = textViewInsets
        }
    }
}
