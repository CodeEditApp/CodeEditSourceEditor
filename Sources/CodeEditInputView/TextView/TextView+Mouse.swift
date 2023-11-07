//
//  TextView+Mouse.swift
//  
//
//  Created by Khan Winter on 9/19/23.
//

import AppKit
import Common

extension TextView {
    override public func mouseDown(with event: NSEvent) {
        // Set cursor
        guard isSelectable,
              event.type == .leftMouseDown,
              let offset = layoutManager.textOffsetAtPoint(self.convert(event.locationInWindow, from: nil)) else {
            super.mouseDown(with: event)
            return
        }

        switch event.clickCount {
        case 1:
            if event.modifierFlags.intersection(.deviceIndependentFlagsMask).isSuperset(of: [.control, .shift]) {
                unmarkText()
                selectionManager.addSelectedRange(NSRange(location: offset, length: 0))
            } else {
                selectionManager.setSelectedRange(NSRange(location: offset, length: 0))
            }
        case 2:
            unmarkText()
            selectWord(nil)
        case 3:
            unmarkText()
            selectLine(nil)
        default:
            break
        }

        mouseDragTimer?.invalidate()
        // https://cocoadev.github.io/AutoScrolling/ (fired at ~45Hz)
        mouseDragTimer = Timer.scheduledTimer(withTimeInterval: 0.022, repeats: true) { [weak self] _ in
            if let event = self?.window?.currentEvent, event.type == .leftMouseDragged {
                self?.mouseDragged(with: event)
                self?.autoscroll(with: event)
            }
        }

        if !self.isFirstResponder {
            self.window?.makeFirstResponder(self)
        }
    }

    override public func mouseUp(with event: NSEvent) {
        mouseDragAnchor = nil
        mouseDragTimer?.invalidate()
        mouseDragTimer = nil
        super.mouseUp(with: event)
    }

    override public func mouseDragged(with event: NSEvent) {
        guard !(inputContext?.handleEvent(event) ?? false) && isSelectable else {
            return
        }

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
