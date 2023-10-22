//
//  CursorView.swift
//  
//
//  Created by Khan Winter on 8/15/23.
//

import AppKit

fileprivate class CursorTimerService {
    static let notification: NSNotification.Name = .init("com.CodeEdit.CursorTimerService.notification")
    var timer: Timer?
    var isHidden: Bool = false
    var listeners: Int = 0

    func setUpTimer(blinkDuration: TimeInterval?) {
        assertMain()
        timer?.invalidate()
        timer = nil
        isHidden = false
        NotificationCenter.default.post(name: Self.notification, object: nil)
        if let blinkDuration {
            timer = Timer.scheduledTimer(withTimeInterval: blinkDuration, repeats: true, block: { [weak self] _ in
                self?.timerReceived()
            })
        }
        listeners += 1
    }

    func timerReceived() {
        assertMain()
        isHidden.toggle()
        NotificationCenter.default.post(name: Self.notification, object: nil)
    }

    func destroySharedTimer() {
        assertMain()
        listeners -= 1
        if listeners == 0 {
            timer?.invalidate()
            timer = nil
            isHidden = false
        }
    }

    private func assertMain() {
#if DEBUG
        assert(Thread.isMainThread, "CursorTimerService used from non-main thread. This may cause a race condition.")
#endif
    }
}

/// Animates a cursor.
open class CursorView: NSView {
    fileprivate static let timerService: CursorTimerService = CursorTimerService()

    public var color: NSColor {
        didSet {
            layer?.backgroundColor = color.cgColor
        }
    }

    private let blinkDuration: TimeInterval?
    private let width: CGFloat
    private var observer: NSObjectProtocol?

    open override var isFlipped: Bool {
        true
    }

    /// Create a cursor view.
    /// - Parameters:
    ///   - blinkDuration: The duration to blink, leave as nil to never blink.
    ///   - color: The color of the cursor.
    ///   - width: How wide the cursor should be.
    init(
        blinkDuration: TimeInterval? = 0.5,
        color: NSColor = NSColor.labelColor,
        width: CGFloat = 1.0
    ) {
        self.blinkDuration = blinkDuration
        self.color = color
        self.width = width

        super.init(frame: .zero)

        frame.size.width = width
        wantsLayer = true
        layer?.backgroundColor = color.cgColor

        CursorView.timerService.setUpTimer(blinkDuration: blinkDuration)

        observer = NotificationCenter.default.addObserver(
            forName: CursorTimerService.notification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isHidden = CursorView.timerService.isHidden
        }
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
        self.observer = nil
        CursorView.timerService.destroySharedTimer()
    }
}
