//
//  SuggestionController+Window.swift
//  CodeEditTextView
//
//  Created by Abe Malla on 12/22/24.
//

import AppKit

extension SuggestionController {
    /// Will constrain the window's frame to be within the visible screen
    public func constrainWindowToScreenEdges(cursorRect: NSRect) {
        guard let window = self.window,
              let screenFrame = window.screen?.visibleFrame else {
            return
        }

        let windowSize = window.frame.size
        let padding: CGFloat = 22
        var newWindowOrigin = NSPoint(
            x: cursorRect.origin.x - Self.WINDOW_PADDING,
            y: cursorRect.origin.y
        )

        // Keep the horizontal position within the screen and some padding
        let minX = screenFrame.minX + padding
        let maxX = screenFrame.maxX - windowSize.width - padding

        if newWindowOrigin.x < minX {
            newWindowOrigin.x = minX
        } else if newWindowOrigin.x > maxX {
            newWindowOrigin.x = maxX
        }

        // Check if the window will go below the screen
        // We determine whether the window drops down or upwards by choosing which
        // corner of the window we will position: `setFrameOrigin` or `setFrameTopLeftPoint`
        if newWindowOrigin.y - windowSize.height < screenFrame.minY {
            // If the cursor itself is below the screen, then position the window
            // at the bottom of the screen with some padding
            if newWindowOrigin.y < screenFrame.minY {
                newWindowOrigin.y = screenFrame.minY + padding
            } else {
                // Place above the cursor
                newWindowOrigin.y += cursorRect.height
            }

            isWindowAboveCursor = true
            window.setFrameOrigin(newWindowOrigin)
        } else {
            // If the window goes above the screen, position it below the screen with padding
            let maxY = screenFrame.maxY - padding
            if newWindowOrigin.y > maxY {
                newWindowOrigin.y = maxY
            }

            isWindowAboveCursor = false
            window.setFrameTopLeftPoint(newWindowOrigin)
        }
    }

    // MARK: - Private Methods

    static func makeWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: self.DEFAULT_SIZE),
            styleMask: [.resizable, .fullSizeContentView, .nonactivatingPanel, .utilityWindow],
            backing: .buffered,
            defer: false
        )

        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isExcludedFromWindowsMenu = true
        window.isReleasedWhenClosed = false
        window.level = .popUpMenu
        window.hasShadow = true
        window.isOpaque = false
        window.tabbingMode = .disallowed
        window.hidesOnDeactivate = true
        window.backgroundColor = .clear
        window.minSize = Self.DEFAULT_SIZE

        return window
    }

    /// Updates the item box window's height based on the number of items.
    /// If there are no items, the default label will be displayed instead.
    func updateSuggestionWindowAndContents() {
        guard let window = self.window else {
            return
        }

        // Update window dimensions
        let numberOfVisibleRows = min(CGFloat(model.items.count), Self.MAX_VISIBLE_ROWS)
        let newHeight = model.items.count == 0 ?
            Self.rowsToWindowHeight(for: 1) : // Height for 1 row when empty
            Self.rowsToWindowHeight(for: numberOfVisibleRows)

        let currentFrame = window.frame
        if isWindowAboveCursor {
            // When window is above cursor, maintain the bottom position
            let bottomY = currentFrame.minY
            let newFrame = NSRect(
                x: currentFrame.minX,
                y: bottomY,
                width: Self.DEFAULT_SIZE.width,
                height: newHeight
            )
            window.setFrame(newFrame, display: true)
        } else {
            // When window is below cursor, maintain the top position
            window.setContentSize(NSSize(width: Self.DEFAULT_SIZE.width, height: newHeight))
        }

        // Dont allow vertical resizing
        window.maxSize = NSSize(width: CGFloat.infinity, height: newHeight)
        window.minSize = NSSize(width: Self.DEFAULT_SIZE.width, height: newHeight)
    }

    /// Calculate the window height for a given number of rows.
    static func rowsToWindowHeight(for numberOfRows: CGFloat) -> CGFloat {
        let wholeRows = floor(numberOfRows)
        let partialRow = numberOfRows - wholeRows

        let baseHeight = ROW_HEIGHT * wholeRows
        let partialHeight = partialRow > 0 ? ROW_HEIGHT * partialRow : 0

        // Add window padding only for whole numbers
        let padding = numberOfRows.truncatingRemainder(dividingBy: 1) == 0 ? WINDOW_PADDING * 2 : WINDOW_PADDING

        return baseHeight + partialHeight + padding
    }
}
