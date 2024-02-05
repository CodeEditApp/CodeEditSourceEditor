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
        scrollView = NSScrollView()
        textView.postsFrameChangedNotifications = true
        textView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.contentView.postsFrameChangedNotifications = true
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.documentView = textView
        scrollView.contentView.postsBoundsChangedNotifications = true
        if let contentInsets {
            scrollView.automaticallyAdjustsContentInsets = false
            scrollView.contentInsets = contentInsets
        }

        gutterView = GutterView(
            font: font.rulerFont,
            textColor: .secondaryLabelColor,
            textView: textView,
            delegate: self
        )
        gutterView.frame.origin.y = -scrollView.contentInsets.top
        gutterView.updateWidthIfNeeded()
        scrollView.addFloatingSubview(
            gutterView,
            for: .horizontal
        )

        self.view = scrollView
        if let _undoManager {
            textView.setUndoManager(_undoManager)
        }

        styleTextView()
        styleGutterView()
        styleScrollView()
        setUpHighlighter()
        setUpTextFormation()

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
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
    }
}
