//
//  TextViewController+LoadView.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 10/14/23.
//

import CodeEditTextView
import AppKit

extension TextViewController {
    // swiftlint:disable:next function_body_length
    override public func loadView() {
        super.loadView()

        scrollView = NSScrollView()
        scrollView.documentView = textView

        gutterView = GutterView(
            font: font.rulerFont,
            textColor: theme.text.color.withAlphaComponent(0.35),
            selectedTextColor: theme.text.color,
            textView: textView,
            delegate: self
        )
        gutterView.updateWidthIfNeeded()
        scrollView.addFloatingSubview(
            gutterView,
            for: .horizontal
        )

        let searchController = FindViewController(target: self, childView: scrollView)
        addChild(searchController)
        self.view.addSubview(searchController.view)
        searchController.view.viewDidMoveToSuperview()
        self.searchController = searchController

        if let _undoManager {
            textView.setUndoManager(_undoManager)
        }

        styleTextView()
        styleScrollView()
        styleGutterView()
        setUpHighlighter()
        setUpTextFormation()

        NSLayoutConstraint.activate([
            searchController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchController.view.topAnchor.constraint(equalTo: view.topAnchor),
            searchController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        if !cursorPositions.isEmpty {
            setCursorPositions(cursorPositions)
        }

        // Layout on scroll change
        NotificationCenter.default.addObserver(
            forName: NSView.boundsDidChangeNotification,
            object: scrollView.contentView,
            queue: .main
        ) { [weak self] _ in
            self?.textView.updatedViewport(self?.scrollView.documentVisibleRect ?? .zero)
            self?.gutterView.needsDisplay = true
        }

        // Layout on frame change
        NotificationCenter.default.addObserver(
            forName: NSView.frameDidChangeNotification,
            object: scrollView.contentView,
            queue: .main
        ) { [weak self] _ in
            self?.textView.updatedViewport(self?.scrollView.documentVisibleRect ?? .zero)
            self?.gutterView.needsDisplay = true
            if self?.bracketPairEmphasis == .flash {
                self?.emphasisManager?.removeEmphases(for: "bracketPairs")
            }
        }

        NotificationCenter.default.addObserver(
            forName: NSView.frameDidChangeNotification,
            object: textView,
            queue: .main
        ) { [weak self] _ in
            self?.gutterView.frame.size.height = (self?.textView.frame.height ?? 0) + 10
            self?.gutterView.needsDisplay = true
        }

        NotificationCenter.default.addObserver(
            forName: TextSelectionManager.selectionChangedNotification,
            object: textView.selectionManager,
            queue: .main
        ) { [weak self] _ in
            self?.updateCursorPosition()
            self?.emphasizeSelectionPairs()
        }

        textView.updateFrameIfNeeded()

        NSApp.publisher(for: \.effectiveAppearance)
            .receive(on: RunLoop.main)
            .sink { [weak self] newValue in
                guard let self = self else { return }

                if self.systemAppearance != newValue.name {
                    self.systemAppearance = newValue.name

                    // Reset content insets and gutter position when appearance changes
                    if let contentInsets = self.contentInsets {
                        self.scrollView.contentInsets = contentInsets
                        if let searchController = self.searchController, searchController.isShowingFindPanel {
                            self.scrollView.contentInsets.top += FindPanel.height
                        }
                        self.gutterView.frame.origin.y = -self.scrollView.contentInsets.top
                    }
                }
            }
            .store(in: &cancellables)

        if let localEventMonitor = self.localEvenMonitor {
            NSEvent.removeMonitor(localEventMonitor)
        }
        setUpKeyBindings(eventMonitor: &self.localEvenMonitor)
    }

    func setUpKeyBindings(eventMonitor: inout Any?) {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event -> NSEvent? in
            guard let self = self else { return event }

            // Check if this window is key and if the text view is the first responder
            let isKeyWindow = self.view.window?.isKeyWindow ?? false
            let isFirstResponder = self.view.window?.firstResponder === self.textView

            // Only handle commands if this is the key window and text view is first responder
            guard isKeyWindow && isFirstResponder else { return event }

            let modifierFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            return self.handleCommand(event: event, modifierFlags: modifierFlags.rawValue)
        }
    }

    func handleCommand(event: NSEvent, modifierFlags: UInt) -> NSEvent? {
        let commandKey = NSEvent.ModifierFlags.command.rawValue

        switch (modifierFlags, event.charactersIgnoringModifiers) {
        case (commandKey, "/"):
            handleCommandSlash()
            return nil
        case (commandKey, "["):
            handleIndent(inwards: true)
            return nil
        case (commandKey, "]"):
            handleIndent()
            return nil
        case (commandKey, "f"):
            _ = self.textView.resignFirstResponder()
            self.searchController?.showFindPanel()
            return nil
        case (0, "\u{1b}"): // Escape key
            self.searchController?.findPanel.cancel()
            return nil
        case (_, _):
            return event
        }
    }

    /// Handles the tab key event.
    /// If the Shift key is pressed, it handles unindenting. If no modifier key is pressed, it checks if multiple lines
    /// are highlighted and handles indenting accordingly.
    ///
    /// - Returns: The original event if it should be passed on, or `nil` to indicate handling within the method.
    func handleTab(event: NSEvent, modifierFalgs: UInt) -> NSEvent? {
        let shiftKey = NSEvent.ModifierFlags.shift.rawValue

        if modifierFalgs == shiftKey {
            handleIndent(inwards: true)
        } else {
            // Only allow tab to work if multiple lines are selected
            guard multipleLinesHighlighted() else { return event }
            handleIndent()
        }
        return nil
    }
}
