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
final class FindPanel: NSHostingView<FindPanelView> {
    private weak var viewModel: FindPanelViewModel?

    private var eventMonitor: Any?

    init(viewModel: FindPanelViewModel) {
        self.viewModel = viewModel
        super.init(rootView: FindPanelView(viewModel: viewModel))

        self.translatesAutoresizingMaskIntoConstraints = false

        self.wantsLayer = true
        self.layer?.backgroundColor = .clear

        self.translatesAutoresizingMaskIntoConstraints = false
    }

    @MainActor @preconcurrency required init(rootView: FindPanelView) {
        super.init(rootView: rootView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        removeEventMonitor()
    }

    // MARK: - Event Monitor Management

    func addEventMonitor() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event -> NSEvent? in
            if event.keyCode == 53 { // if esc pressed
                self.viewModel?.dismiss?()
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
}
