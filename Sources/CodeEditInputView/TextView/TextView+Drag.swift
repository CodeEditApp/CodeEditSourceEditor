//
//  TextView+Drag.swift
//  
//
//  Created by Khan Winter on 9/19/23.
//

import AppKit
import Common

extension TextView {
    public override func mouseDragged(with event: NSEvent) {
        if mouseDragAnchor == nil {
            mouseDragAnchor = convert(event.locationInWindow, from: nil)
            super.mouseDragged(with: event)
        } else {
            guard let mouseDragAnchor,
                  let startPosition = layoutManager.textOffsetAtPoint(mouseDragAnchor),
                  let endPosition = layoutManager.textOffsetAtPoint(convert(event.locationInWindow, from: nil)) else {
                return
            }
            selectionManager.setSelectedRange(
                NSRange(
                    location: min(startPosition, endPosition),
                    length: max(startPosition, endPosition) - min(startPosition, endPosition)
                )
            )
            setNeedsDisplay()
            self.autoscroll(with: event)
        }
    }
}
