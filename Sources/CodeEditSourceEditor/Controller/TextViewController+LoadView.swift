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

        let searchController = SearchViewController(target: self, childView: scrollView)
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
        self.localEvenMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event -> NSEvent? in
            guard self?.view.window?.firstResponder == self?.textView else { return event }
            let modifierFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

            switch (modifierFlags, event.charactersIgnoringModifiers?.lowercased()) {
            case (.command, "/"):
                self?.handleCommandSlash()
                return nil
            case (.command, "f"):
                _ = self?.textView.resignFirstResponder()
                self?.searchController?.showSearchBar()
                return nil
            case ([], "\u{1b}"): // Escape key
                self?.searchController?.hideSearchBar()
                _ = self?.textView.becomeFirstResponder()
                self?.textView.selectionManager.setSelectedRanges(
                    self?.textView.selectionManager.textSelections.map { $0.range } ?? []
                )
                return nil
            default:
                return event
            }
        }
    }
}
