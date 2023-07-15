//
//  STTextViewController+TextContainer.swift
//  
//
//  Created by Khan Winter on 4/21/23.
//

import AppKit
import STTextView

extension STTextViewController {
    /// Update the text view's text container if needed.
    ///
    /// Effectively updates the container to reflect the `wrapLines` setting, and to reflect any updates to the ruler,
    /// scroll view, or window frames.
    internal func updateTextContainerWidthIfNeeded(_ forceUpdate: Bool = false) {
        let previousTrackingSetting = textView.widthTracksTextView
        textView.widthTracksTextView = wrapLines
        guard let scrollView = view as? NSScrollView else {
            return
        }

        if wrapLines {
            var proposedSize = scrollView.contentSize
            proposedSize.height = .greatestFiniteMagnitude

            if textView.textContainer.size != proposedSize || textView.frame.size != proposedSize || forceUpdate {
                textView.textContainer.size = proposedSize
                textView.setFrameSize(proposedSize)
            }
        } else {
            var proposedSize = textView.frame.size
            proposedSize.width = scrollView.contentSize.width
            if previousTrackingSetting != wrapLines || forceUpdate {
                textView.textContainer.size = CGSize(
                    width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude
                )
                textView.setFrameSize(proposedSize)
                textView.textLayoutManager.textViewportLayoutController.layoutViewport()
            }
        }
    }
}
