//
//  TextViewController+LoadView.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 10/14/23.
//

import CodeEditTextView
import AppKit

extension TextViewController {
    override public func loadView() {
        super.loadView()

        scrollView = NSScrollView()
        scrollView.documentView = textView

        gutterView = GutterView(
            configuration: configuration,
            textView: textView,
            delegate: self
        )
        gutterView.updateWidthIfNeeded()
        scrollView.addFloatingSubview(gutterView, for: .horizontal)

        reformattingGuideView = ReformattingGuideView(configuration: configuration)
        scrollView.addFloatingSubview(reformattingGuideView, for: .vertical)

        minimapView = MinimapView(textView: textView, theme: configuration.appearance.theme)
        scrollView.addFloatingSubview(minimapView, for: .vertical)

        let findViewController = FindViewController(target: self, childView: scrollView)
        addChild(findViewController)
        self.findViewController = findViewController
        self.view.addSubview(findViewController.view)
        findViewController.view.viewDidMoveToSuperview()
        self.findViewController = findViewController

        if let _undoManager {
            textView.setUndoManager(_undoManager)
        }

        styleTextView()
        styleScrollView()
        styleGutterView()
        styleMinimapView()

        setUpHighlighter()
        setUpTextFormation()

        if !cursorPositions.isEmpty {
            setCursorPositions(cursorPositions)
        }

        setUpConstraints()
        setUpOberservers()

        textView.updateFrameIfNeeded()

        if let localEventMonitor = self.localEvenMonitor {
            NSEvent.removeMonitor(localEventMonitor)
        }
        setUpKeyBindings(eventMonitor: &self.localEvenMonitor)
        updateContentInsets()

        configuration.didSetOnController(controller: self, oldConfig: nil)
    }

    func setUpConstraints() {
        guard let findViewController else { return }

        let maxWidthConstraint = minimapView.widthAnchor.constraint(lessThanOrEqualToConstant: MinimapView.maxWidth)
        let relativeWidthConstraint = minimapView.widthAnchor.constraint(
            equalTo: view.widthAnchor,
            multiplier: 0.17
        )
        relativeWidthConstraint.priority = .defaultLow
        let minimapXConstraint = minimapView.trailingAnchor.constraint(
            equalTo: scrollView.contentView.safeAreaLayoutGuide.trailingAnchor
        )
        self.minimapXConstraint = minimapXConstraint

        NSLayoutConstraint.activate([
            findViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            findViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            findViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            findViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            minimapView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor),
            minimapView.bottomAnchor.constraint(equalTo: scrollView.contentView.bottomAnchor),
            minimapXConstraint,
            maxWidthConstraint,
            relativeWidthConstraint
        ])
    }

    func setUpOnScrollChangeObserver() {
        NotificationCenter.default.addObserver(
            forName: NSView.boundsDidChangeNotification,
            object: scrollView.contentView,
            queue: .main
        ) { [weak self] notification in
            guard let clipView = notification.object as? NSClipView else { return }
            self?.gutterView.needsDisplay = true
            self?.minimapXConstraint?.constant = clipView.bounds.origin.x
            NotificationCenter.default.post(name: Self.scrollPositionDidUpdateNotification, object: self)
        }
    }

    func setUpOnScrollViewFrameChangeObserver() {
        NotificationCenter.default.addObserver(
            forName: NSView.frameDidChangeNotification,
            object: scrollView.contentView,
            queue: .main
        ) { [weak self] _ in
            self?.gutterView.needsDisplay = true
            self?.emphasisManager?.removeEmphases(for: EmphasisGroup.brackets)
            self?.updateTextInsets()
            NotificationCenter.default.post(name: Self.scrollPositionDidUpdateNotification, object: self)
        }
    }

    func setUpTextViewFrameChangeObserver() {
        NotificationCenter.default.addObserver(
            forName: NSView.frameDidChangeNotification,
            object: textView,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.gutterView.frame.size.height = self.textView.frame.height + 10
            self.gutterView.frame.origin.y = self.textView.frame.origin.y - self.scrollView.contentInsets.top
            self.gutterView.needsDisplay = true
            self.reformattingGuideView?.updatePosition(in: self)
            self.scrollView.needsLayout = true
        }
    }

    func setUpSelectionChangedObserver() {
        NotificationCenter.default.addObserver(
            forName: TextSelectionManager.selectionChangedNotification,
            object: textView.selectionManager,
            queue: .main
        ) { [weak self] _ in
            self?.updateCursorPosition()
            self?.emphasizeSelectionPairs()
        }
    }

    func setUpAppearanceChangedObserver() {
        NSApp.publisher(for: \.effectiveAppearance)
            .receive(on: RunLoop.main)
            .sink { [weak self] newValue in
                guard let self = self else { return }

                if self.systemAppearance != newValue.name {
                    self.systemAppearance = newValue.name

                    // Reset content insets and gutter position when appearance changes
                    self.styleScrollView()
                    self.gutterView.frame.origin.y = self.textView.frame.origin.y - self.scrollView.contentInsets.top
                }
            }
            .store(in: &cancellables)
    }

    func setUpOberservers() {
        setUpOnScrollChangeObserver()
        setUpOnScrollViewFrameChangeObserver()
        setUpTextViewFrameChangeObserver()
        setUpSelectionChangedObserver()
        setUpAppearanceChangedObserver()
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
            let tabKey: UInt16 = 0x30

            if event.keyCode == tabKey {
                return self.handleTab(event: event, modifierFalgs: modifierFlags.rawValue)
            } else {
                return self.handleCommand(event: event, modifierFlags: modifierFlags.rawValue)
            }
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
            self.findViewController?.showFindPanel()
            return nil
        case (0, "\u{1b}"): // Escape key
            self.findViewController?.hideFindPanel()
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
