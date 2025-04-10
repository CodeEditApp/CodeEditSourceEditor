//
//  FindPanel.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 3/10/25.
//

import SwiftUI
import AppKit
import Combine

// NSView wrapper for using SwiftUI view in AppKit
final class FindPanel: NSView {
    /// The height of the find panel.
    static var height: CGFloat {
        if let findPanel = NSApp.windows.first(where: { $0.contentView is FindPanel })?.contentView as? FindPanel {
            return findPanel.viewModel.mode == .replace ? 56 : 28
        }
        return 28
    }

    weak var findDelegate: FindPanelDelegate?
    private var hostingView: NSHostingView<FindPanelView>!
    private var viewModel: FindPanelViewModel!
    private weak var textView: NSView?
    private var isViewReady = false
    private var findQueryText: String = "" // Store search text at panel level
    private var eventMonitor: Any?

    init(delegate: FindPanelDelegate?, textView: NSView?) {
        self.findDelegate = delegate
        self.textView = textView
        super.init(frame: .zero)

        viewModel = FindPanelViewModel(delegate: findDelegate)
        viewModel.findText = findQueryText // Initialize with stored value
        hostingView = NSHostingView(rootView: FindPanelView(viewModel: viewModel))
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        // Make the NSHostingView transparent
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = .clear

        // Make the FindPanel itself transparent
        self.wantsLayer = true
        self.layer?.backgroundColor = .clear

        addSubview(hostingView)

        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: topAnchor),
            hostingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostingView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        self.translatesAutoresizingMaskIntoConstraints = false
    }

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        if !isViewReady && superview != nil {
            isViewReady = true
            viewModel.startObservingFindText()
        }
    }

    deinit {
        removeEventMonitor()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var fittingSize: NSSize {
        hostingView.fittingSize
    }

    // MARK: - First Responder Management

    override func becomeFirstResponder() -> Bool {
        viewModel.setFocus(true)
        return true
    }

    override func resignFirstResponder() -> Bool {
        viewModel.setFocus(false)
        return true
    }

    // MARK: - Event Monitor Management

    func addEventMonitor() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event -> NSEvent? in
            if event.keyCode == 53 { // if esc pressed
                self.dismiss()
                return nil // do not play "beep" sound
            }
            return event
        }
    }

    func removeEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    // MARK: - Public Methods

    func dismiss() {
        viewModel.onDismiss()
    }

    func updateMatchCount(_ count: Int) {
        viewModel.updateMatchCount(count)
    }

    // MARK: - Search Text Management

    func updateSearchText(_ text: String) {
        findQueryText = text
        viewModel.findText = text
        findDelegate?.findPanelDidUpdate(text)
    }
}
