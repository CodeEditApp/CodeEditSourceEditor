//
//  CEScrollView.swift
//  
//
//  Created by Renan Greca on 18/02/23.
//

import AppKit
import STTextView

class CEScrollView: NSScrollView {

    override open var contentSize: NSSize {
        var proposedSize = super.contentSize
        proposedSize.width -= verticalRulerView?.requiredThickness ?? 0.0
        return proposedSize
    }

    override func mouseDown(with event: NSEvent) {

        if let textView = self.documentView as? STTextView,
            !textView.visibleRect.contains(event.locationInWindow) {
            // If the `scrollView` was clicked, but the click did not happen within the `textView`,
            // set cursor to the last index of the `textView`.

            let endLocation = textView.textLayoutManager.documentRange.endLocation
            let range = NSTextRange(location: endLocation)
            _ = textView.becomeFirstResponder()
            textView.setSelectedTextRange(range)
        }

        super.mouseDown(with: event)
    }
}
