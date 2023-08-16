//
//  CursorView.swift
//  
//
//  Created by Khan Winter on 8/15/23.
//

import AppKit

/// Animates a cursor.
class CursorView: NSView {
    let blinkDuration: TimeInterval?
    let color: CGColor
    let width: CGFloat

    private var timer: Timer?

    override var isFlipped: Bool {
        true
    }

    /// Create a cursor view.
    /// - Parameters:
    ///   - blinkDuration: The duration to blink, leave as nil to never blink.
    ///   - color: The color of the cursor.
    ///   - width: How wide the cursor should be.
    init(
        blinkDuration: TimeInterval? = 0.5,
        color: CGColor = NSColor.controlAccentColor.cgColor,
        width: CGFloat = 2.0
    ) {
        self.blinkDuration = blinkDuration
        self.color = color
        self.width = width

        super.init(frame: .zero)

        frame.size.width = width
        wantsLayer = true
        layer?.backgroundColor = color

        if let blinkDuration {
            timer = Timer.scheduledTimer(withTimeInterval: blinkDuration, repeats: true, block: { _ in
                self.isHidden.toggle()
            })
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        timer?.invalidate()
    }
}
