//
//  SuggestionController.swift
//  CodeEditTextView
//
//  Created by Abe Malla on 6/18/24.
//

import AppKit

/// Represents an item that can be displayed in the code suggestion view
public protocol CodeSuggestionEntry {
    var view: NSView { get }
}

public final class SuggestionController: NSWindowController {

    // MARK: - Properties

    public static var DEFAULT_SIZE: NSSize {
        NSSize(
            width: 256, // TODO: DOES MIN WIDTH DEPEND ON FONT SIZE?
            height: rowsToWindowHeight(for: 1)
        )
    }

    /// The items to be displayed in the window
    public var items: [CodeSuggestionEntry] = [] {
        didSet { onItemsUpdated() }
    }

    /// Whether the suggestion window is visbile
    public var isVisible: Bool {
        window?.isVisible ?? false
    }

    public weak var delegate: SuggestionControllerDelegate?

    // MARK: - Private Properties

    /// Height of a single row
    static let ROW_HEIGHT: CGFloat = 21
    /// Maximum number of visible rows (8.5)
    static let MAX_VISIBLE_ROWS: CGFloat = 8.5
    /// Padding at top and bottom of the window
    static let WINDOW_PADDING: CGFloat = 5

    let tableView = NSTableView()
    let scrollView = NSScrollView()
    let popover = NSPopover()
    /// Tracks when the window is placed above the cursor
    var isWindowAboveCursor = false

    let noItemsLabel: NSTextField = {
        let label = NSTextField(labelWithString: "No Completions")
        label.textColor = .secondaryLabelColor
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = false
        // TODO: GET FONT SIZE FROM THEME
        label.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        return label
    }()

    /// An event monitor for keyboard events
    private var localEventMonitor: Any?
    /// Holds the observer for the window resign notifications
    private var windowResignObserver: NSObjectProtocol?
    /// Holds the observer for the cursor position update notifications
    private var cursorPositionObserver: NSObjectProtocol?

    // MARK: - Initialization

    public init() {
        let window = Self.makeWindow()
        super.init(window: window)
        configureTableView()
        configureScrollView()
        configureNoItemsLabel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Opens the window as a child of another window.
    public func showWindow(attachedTo parentWindow: NSWindow) {
        guard let window = window else { return }

        parentWindow.addChildWindow(window, ordered: .above)
        window.orderFront(nil)

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

        self.show()
    }

    /// Opens the window of items
    func show() {
        setupEventMonitors()
        resetScrollPosition()
        super.showWindow(nil)
    }

    /// Close the window
    public override func close() {
        guard isVisible else { return }
        removeEventMonitors()
        super.close()
    }

    private func onItemsUpdated() {
        updateSuggestionWindowAndContents()
        resetScrollPosition()
        tableView.reloadData()
    }

    private func setupEventMonitors() {
        localEventMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.keyDown, .leftMouseDown, .rightMouseDown]
        ) { [weak self] event in
            guard let self = self else { return event }

            switch event.type {
            case .keyDown:
                return checkKeyDownEvents(event)

            case .leftMouseDown, .rightMouseDown:
                // If we click outside the window, close the window
                if !NSMouseInRect(NSEvent.mouseLocation, self.window!.frame, false) {
                    self.close()
                }
                return event

            default:
                return event
            }
        }

        if let existingObserver = cursorPositionObserver {
            NotificationCenter.default.removeObserver(existingObserver)
        }
        cursorPositionObserver = NotificationCenter.default.addObserver(
            forName: TextViewController.cursorPositionUpdatedNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let textViewController = notification.object as? TextViewController
            else { return }

            guard self.isVisible else { return }
            self.delegate?.onCursorMove()
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
            self.tableView.keyDown(with: event)
            guard tableView.selectedRow >= 0 else { return event }
            let selectedItem = items[tableView.selectedRow]
            self.delegate?.onItemSelect(item: selectedItem)
            return nil

        case 124: // Right Arrow
//          handleRightArrow()
            return event

        case 123: // Left Arrow
            return event

        case 36, 48:  // Return/Tab
            guard tableView.selectedRow >= 0 else { return event }
            let selectedItem = items[tableView.selectedRow]
            self.delegate?.applyCompletionItem(item: selectedItem)
            self.close()
            return nil

        default:
            return event
        }
    }

    private func handleRightArrow() {
        guard let window = self.window,
              let selectedRow = tableView.selectedRowIndexes.first,
              selectedRow < items.count,
              !popover.isShown else {
            return
        }
        let rowRect = tableView.rect(ofRow: selectedRow)
        let rowRectInWindow = tableView.convert(rowRect, to: nil)
        let popoverPoint = NSPoint(
            x: window.frame.maxX,
            y: window.frame.minY + rowRectInWindow.midY
        )
        popover.show(
            relativeTo: NSRect(x: popoverPoint.x, y: popoverPoint.y, width: 1, height: 1),
            of: window.contentView!,
            preferredEdge: .maxX
        )
    }

    private func resetScrollPosition() {
        guard let clipView = scrollView.contentView as? NSClipView else { return }

        // Scroll to the top of the content
        clipView.scroll(to: NSPoint(x: 0, y: -Self.WINDOW_PADDING))

        // Select the first item
        if !items.isEmpty {
            tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
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
        if let observer = cursorPositionObserver {
            NotificationCenter.default.removeObserver(observer)
            cursorPositionObserver = nil
        }
    }

    deinit {
        removeEventMonitors()
    }
}
