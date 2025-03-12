//
//  FindViewController.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 3/10/25.
//

import AppKit

/// Creates a container controller for displaying and hiding a search bar with a content view.
final class FindViewController: NSViewController {
    weak var target: FindTarget?
    var childView: NSView
    var findPanel: FindPanel!

    private var findPanelVerticalConstraint: NSLayoutConstraint!

    private(set) public var isShowingFindPanel: Bool = false

    init(target: FindTarget, childView: NSView) {
        self.target = target
        self.childView = childView
        super.init(nibName: nil, bundle: nil)
        self.findPanel = FindPanel(delegate: self, textView: target as? NSView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        super.loadView()

        // Set up the `childView` as a subview of our view. Constrained to all edges, except the top is constrained to
        // the search bar's bottom
        // The search bar is constrained to the top of the view.
        // The search bar's top anchor when hidden, is equal to it's negated height hiding it above the view's contents.
        // When visible, it's set to 0.

        view.addSubview(findPanel)
        view.addSubview(childView)

        // Ensure find panel is always on top
        findPanel.wantsLayer = true
        findPanel.layer?.zPosition = 1000

        findPanelVerticalConstraint = findPanel.topAnchor.constraint(equalTo: view.topAnchor)

        NSLayoutConstraint.activate([
            // Constrain search bar
            findPanelVerticalConstraint,
            findPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            findPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // Constrain child view
            childView.topAnchor.constraint(equalTo: findPanel.bottomAnchor),
            childView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            childView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            childView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        if isShowingFindPanel { // Update constraints for initial state
            showFindPanel()
        } else {
            hideFindPanel()
        }
    }
}

// MARK: - Toggle Search Bar

extension FindViewController {
    /// Toggle the search bar
    func toggleFindPanel() {
        if isShowingFindPanel {
            hideFindPanel()
        } else {
            showFindPanel()
        }
    }

    /// Show the search bar
    func showFindPanel() {
        if !isShowingFindPanel {
            isShowingFindPanel = true
            withAnimation {
                // Update the search bar's top to be equal to the view's top.
                findPanelVerticalConstraint.constant = 0
                findPanelVerticalConstraint.isActive = true
            }
        }
        _ = findPanel?.becomeFirstResponder()
    }

    /// Hide the search bar
    func hideFindPanel() {
        isShowingFindPanel = false
        _ = findPanel?.resignFirstResponder()
        withAnimation {
            // Update the search bar's top anchor to be equal to it's negative height, hiding it above the view.
            findPanelVerticalConstraint.constant = -findPanel.fittingSize.height
            findPanelVerticalConstraint.isActive = true
        }
    }

    /// Runs the `animatable` callback in an animation context with implicit animation enabled.
    /// - Parameter animatable: The callback run in the animation context. Perform layout or view updates in this
    ///                         callback to have them animated.
    private func withAnimation(_ animatable: () -> Void) {
        NSAnimationContext.runAnimationGroup { animator in
            animator.duration = 0.2
            animator.allowsImplicitAnimation = true

            animatable()

            view.updateConstraints()
            view.layoutSubtreeIfNeeded()
        }
    }
}

// MARK: - Search Bar Delegate

extension FindViewController: FindPanelDelegate {
    func findPanelOnSubmit() {
        target?.emphasizeAPI?.highlightNext()
        if let textViewController = target as? TextViewController,
           let emphasizeAPI = target?.emphasizeAPI,
           !emphasizeAPI.emphasizedRanges.isEmpty {
            let activeIndex = emphasizeAPI.emphasizedRangeIndex ?? 0
            let range = emphasizeAPI.emphasizedRanges[activeIndex].range
            textViewController.textView.scrollToRange(range)
            textViewController.setCursorPositions([CursorPosition(range: range)])
        }
    }

    func findPanelOnCancel() {
        // Return focus to the editor and restore cursor
        if let textViewController = target as? TextViewController {
            // Get the current highlight range before doing anything else
            var rangeToSelect: NSRange?
            if let emphasizeAPI = target?.emphasizeAPI {
                if !emphasizeAPI.emphasizedRanges.isEmpty {
                    // Get the active highlight range
                    let activeIndex = emphasizeAPI.emphasizedRangeIndex ?? 0
                    rangeToSelect = emphasizeAPI.emphasizedRanges[activeIndex].range
                }
            }

            // Now hide the panel
            if isShowingFindPanel {
                hideFindPanel()
            }

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                // First make the text view first responder
                self.view.window?.makeFirstResponder(textViewController.textView)

                // If we had an active highlight, select it
                if let rangeToSelect = rangeToSelect {
                    // Set the selection first
                    textViewController.textView.selectionManager.setSelectedRanges([rangeToSelect])
                    textViewController.setCursorPositions([CursorPosition(range: rangeToSelect)])
                    textViewController.textView.scrollToRange(rangeToSelect)

                    // Then clear highlights after a short delay to ensure selection is set
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.target?.emphasizeAPI?.removeEmphasizeLayers()
                        textViewController.textView.needsDisplay = true
                    }
                } else if let currentPosition = textViewController.cursorPositions.first {
                    // Otherwise ensure cursor is visible at last position
                    textViewController.textView.scrollToRange(currentPosition.range)
                    textViewController.textView.selectionManager.setSelectedRanges([currentPosition.range])
                    self.target?.emphasizeAPI?.removeEmphasizeLayers()
                }
            }
        }
    }

    func findPanelDidUpdate(_ searchText: String) {
        // Only perform search if we're not handling a mouse click in the text view
        if let textViewController = target as? TextViewController,
           textViewController.textView.window?.firstResponder === textViewController.textView {
            // If the text view has focus, just clear emphasis layers without searching
            target?.emphasizeAPI?.removeEmphasizeLayers()
            findPanel.searchDelegate?.findPanelUpdateMatchCount(0)
            return
        }
        searchFile(query: searchText)
    }

    func findPanelPrevButtonClicked() {
        target?.emphasizeAPI?.highlightPrevious()
        if let textViewController = target as? TextViewController,
           let emphasizeAPI = target?.emphasizeAPI,
           !emphasizeAPI.emphasizedRanges.isEmpty {
            let activeIndex = emphasizeAPI.emphasizedRangeIndex ?? 0
            let range = emphasizeAPI.emphasizedRanges[activeIndex].range
            textViewController.textView.scrollToRange(range)
            textViewController.setCursorPositions([CursorPosition(range: range)])
        }
    }

    func findPanelNextButtonClicked() {
        target?.emphasizeAPI?.highlightNext()
        if let textViewController = target as? TextViewController,
           let emphasizeAPI = target?.emphasizeAPI,
           !emphasizeAPI.emphasizedRanges.isEmpty {
            let activeIndex = emphasizeAPI.emphasizedRangeIndex ?? 0
            let range = emphasizeAPI.emphasizedRanges[activeIndex].range
            textViewController.textView.scrollToRange(range)
            textViewController.setCursorPositions([CursorPosition(range: range)])
        }
    }

    func searchFile(query: String) {
        // Don't search if target or emphasizeAPI isn't ready
        guard let target = target,
              let emphasizeAPI = target.emphasizeAPI else {
            findPanel.searchDelegate?.findPanelUpdateMatchCount(0)
            return
        }

        // Clear highlights and return if query is empty
        if query.isEmpty {
            emphasizeAPI.removeEmphasizeLayers()
            findPanel.searchDelegate?.findPanelUpdateMatchCount(0)
            return
        }

        let searchOptions: NSRegularExpression.Options = smartCase(str: query) ? [] : [.caseInsensitive]
        let escapedQuery = NSRegularExpression.escapedPattern(for: query)

        guard let regex = try? NSRegularExpression(pattern: escapedQuery, options: searchOptions) else {
            emphasizeAPI.removeEmphasizeLayers()
            findPanel.searchDelegate?.findPanelUpdateMatchCount(0)
            return
        }

        let text = target.text
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        guard !matches.isEmpty else {
            emphasizeAPI.removeEmphasizeLayers()
            findPanel.searchDelegate?.findPanelUpdateMatchCount(0)
            return
        }

        let searchResults = matches.map { $0.range }
        findPanel.searchDelegate?.findPanelUpdateMatchCount(searchResults.count)

        // If we have an active highlight and the same number of matches, try to preserve the active index
        let currentActiveIndex = target.emphasizeAPI?.emphasizedRangeIndex ?? 0
        let activeIndex = (target.emphasizeAPI?.emphasizedRanges.count == searchResults.count) ? 
                         currentActiveIndex : 0

        emphasizeAPI.emphasizeRanges(ranges: searchResults, activeIndex: activeIndex)
        
        // Only set cursor position if we're actively searching (not when clearing)
        if !query.isEmpty {
            // Always select the active highlight
            target.setCursorPositions([CursorPosition(range: searchResults[activeIndex])])
        }
    }

    // Only re-serach the part of the file that changed upwards
    private func reSearch() { }

    // Returns true if string contains uppercase letter
    // used for: ignores letter case if the search query is all lowercase
    private func smartCase(str: String) -> Bool {
        return str.range(of: "[A-Z]", options: .regularExpression) != nil
    }

    func findPanelUpdateMatchCount(_ count: Int) {
        findPanel.updateMatchCount(count)
    }

    func findPanelClearEmphasis() {
        target?.emphasizeAPI?.removeEmphasizeLayers()
        findPanel.searchDelegate?.findPanelUpdateMatchCount(0)
    }
}
