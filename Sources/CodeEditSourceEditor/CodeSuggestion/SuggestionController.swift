//
//  SuggestionController.swift
//  CodeEditTextView
//
//  Created by Abe Malla on 6/18/24.
//

import AppKit
import CodeEditTextView
import Combine

public final class SuggestionController: NSWindowController {
    static var shared: SuggestionController = SuggestionController()

    // MARK: - Properties

    static var DEFAULT_SIZE: NSSize {
        NSSize(
            width: 256, // TODO: DOES MIN WIDTH DEPEND ON FONT SIZE?
            height: rowsToWindowHeight(for: 1)
        )
    }

    /// Whether the suggestion window is visibile
    var isVisible: Bool {
        window?.isVisible ?? false
    }

    var itemObserver: AnyCancellable?
    var model: SuggestionViewModel = SuggestionViewModel()

    // MARK: - Private Properties

    /// Height of a single row
    static let ROW_HEIGHT: CGFloat = 21
    /// Maximum number of visible rows (8.5)
    static let MAX_VISIBLE_ROWS: CGFloat = 8.5
    /// Padding at top and bottom of the window
    static let WINDOW_PADDING: CGFloat = 5

    /// Tracks when the window is placed above the cursor
    var isWindowAboveCursor = false

    /// An event monitor for keyboard events
    private var localEventMonitor: Any?
    /// Holds the observer for the window resign notifications
    private var windowResignObserver: NSObjectProtocol?

    // MARK: - Initialization

    public init() {
        let window = Self.makeWindow()

        let controller = SuggestionViewController()
        controller.model = model
        window.contentViewController = controller

        super.init(window: window)

        if window.isVisible {
            window.close()
        }

        itemObserver = model.$items.receive(on: DispatchQueue.main).sink { [weak self] _ in
            self?.onItemsUpdated()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showCompletions(
        textView: TextViewController,
        delegate: CodeSuggestionDelegate,
        cursorPosition: CursorPosition
    ) {
        model.showCompletions(
            textView: textView,
            delegate: delegate,
            cursorPosition: cursorPosition
        ) { parentWindow, cursorRect in
            self.showWindow(attachedTo: parentWindow)
            self.constrainWindowToScreenEdges(cursorRect: cursorRect)
            (self.contentViewController as? SuggestionViewController)?.styleView(using: textView)
        }
    }

    /// Opens the window as a child of another window.
    public func showWindow() {
        guard let window = window,
              let parentWindow = NSApplication.shared.keyWindow
        else { return }

        parentWindow.addChildWindow(window, ordered: .above)

        // Close on window switch observer
        // Initialized outside of `setupEventMonitors` in order to grab the parent window
        if let existingObserver = windowResignObserver {
            NotificationCenter.default.removeObserver(existingObserver)
        }
        windowResignObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: parentWindow,
            queue: .main
        ) { [weak self] _ in
            self?.close()
        }

        setupEventMonitors()
        super.showWindow(nil)
        window.orderFront(nil)
        window.contentViewController?.viewWillAppear()
    }

    /// Close the window
    public override func close() {
        model.willClose()
        removeEventMonitors()
        super.close()
    }

    private func onItemsUpdated() {
        updateSuggestionWindowAndContents()
    }

    private func setupEventMonitors() {
        localEventMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.keyDown]
        ) { [weak self] event in
            guard let self = self else { return event }

            switch event.type {
            case .keyDown:
                return checkKeyDownEvents(event)
            default:
                return event
            }
        }
    }

    private func checkKeyDownEvents(_ event: NSEvent) -> NSEvent? {
        if !self.isVisible {
            return event
        }

        switch event.keyCode {
        case 53: // Escape
            self.close()
            return nil

        case 125, 126:  // Down/Up Arrow
            (contentViewController as? SuggestionViewController)?.tableView?.keyDown(with: event)
            return nil

        case 36, 48:  // Return/Tab
            (contentViewController as? SuggestionViewController)?.applySelectedItem()
            return nil

        default:
            return event
        }
    }

    private func removeEventMonitors() {
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
        if let observer = windowResignObserver {
            NotificationCenter.default.removeObserver(observer)
            windowResignObserver = nil
        }
    }

    func cursorsUpdated(
        textView: TextViewController,
        delegate: CodeSuggestionDelegate,
        position: CursorPosition,
        presentIfNot: Bool = false
    ) {
        model.cursorsUpdated(textView: textView, delegate: delegate, position: position) {
            close()

            if presentIfNot {
                self.showCompletions(textView: textView, delegate: delegate, cursorPosition: position)
            }
        }
    }
}
