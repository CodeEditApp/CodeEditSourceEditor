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
    weak var searchDelegate: FindPanelDelegate?
    private var hostingView: NSHostingView<FindPanelView>!
    private var viewModel: FindPanelViewModel!
    private weak var textView: NSView?
    private var isViewReady = false

    init(delegate: FindPanelDelegate?, textView: NSView?) {
        self.searchDelegate = delegate
        self.textView = textView
        super.init(frame: .zero)

        viewModel = FindPanelViewModel(delegate: searchDelegate)
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
            viewModel.startObservingSearchText()
        }
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

    // MARK: - Public Methods

    func cancel() {
        viewModel.onCancel()
    }

    func updateMatchCount(_ count: Int) {
        viewModel.updateMatchCount(count)
    }
}
