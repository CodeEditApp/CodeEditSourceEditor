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
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.spacing = 10
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false

        scrollView = NSScrollView()
        textView.postsFrameChangedNotifications = true
        textView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.contentView.postsFrameChangedNotifications = true
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = !wrapLines
        scrollView.documentView = textView
        scrollView.contentView.postsBoundsChangedNotifications = true

        gutterView = GutterView(
            font: font.rulerFont,
            textColor: .secondaryLabelColor,
            textView: textView,
            delegate: self
        )
        gutterView.updateWidthIfNeeded()
        scrollView.addFloatingSubview(
            gutterView,
            for: .horizontal
        )

        searchField = NSTextField()
        searchField.placeholderString = "Search..."
        searchField.controlSize = .regular // TODO: a
        searchField.focusRingType = .none
        searchField.bezelStyle = .roundedBezel
        searchField.drawsBackground = true
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.action = #selector(onSubmit)
        searchField.target = self
        
        prevButton = NSButton(title: "◀︎", target: self, action: #selector(prevButtonClicked))
        prevButton.bezelStyle = .texturedRounded
        prevButton.controlSize = .small
        prevButton.translatesAutoresizingMaskIntoConstraints = false

         nextButton = NSButton(title: "▶︎", target: self, action: #selector(nextButtonClicked))
        nextButton.bezelStyle = .texturedRounded
        nextButton.controlSize = .small
        nextButton.translatesAutoresizingMaskIntoConstraints = false

        stackview = NSStackView()
        stackview.orientation = .horizontal
        stackview.spacing = 8
        stackview.edgeInsets = NSEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        stackview.translatesAutoresizingMaskIntoConstraints = false

        stackview.addView(searchField, in: .leading)
        stackview.addView(prevButton, in: .trailing)
        stackview.addView(nextButton, in: .trailing)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(searchFieldUpdated(_:)),
            name: NSControl.textDidChangeNotification,
            object: searchField
        )

        stackView.addArrangedSubview(stackview)
        stackView.addArrangedSubview(scrollView)
        self.view = stackView
        if let _undoManager {
            textView.setUndoManager(_undoManager)
        }

        styleTextView()
        styleScrollView()
        styleGutterView()
        setUpHighlighter()
        setUpTextFormation()

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor)

            //            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
//            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
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
            if self?.bracketPairHighlight == .flash {
                self?.removeHighlightLayers()
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
            self?.highlightSelectionPairs()
        }

        textView.updateFrameIfNeeded()

        NSApp.publisher(for: \.effectiveAppearance)
            .receive(on: RunLoop.main)
            .sink { [weak self] newValue in
                guard let self = self else { return }

                if self.systemAppearance != newValue.name {
                    self.systemAppearance = newValue.name
                }
            }
            .store(in: &cancellables)

        if let localEventMonitor = self.localEvenMonitor {
            NSEvent.removeMonitor(localEventMonitor)
        }
        self.localEvenMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard self?.view.window?.firstResponder == self?.textView else { return event }

            let tabKey: UInt16 = 0x30
            let modifierFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue

            if event.keyCode == tabKey {
                return self?.handleTab(event: event, modifierFalgs: modifierFlags)
            } else {
                return self?.handleCommand(event: event, modifierFlags: modifierFlags)
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
