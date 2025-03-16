//
//  FindViewController.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 3/10/25.
//

import AppKit

/// Creates a container controller for displaying and hiding a search bar with a content view.
final class FindViewController: NSViewController {
    weak var target: FindPanelTarget?
    var childView: NSView
    var findPanel: FindPanel!

    private var findPanelVerticalConstraint: NSLayoutConstraint!

    private(set) public var isShowingFindPanel: Bool = false

    init(target: FindPanelTarget, childView: NSView) {
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

        view.clipsToBounds = false
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
            childView.topAnchor.constraint(equalTo: view.topAnchor),
            childView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            childView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            childView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        if isShowingFindPanel { // Update constraints for initial state
            setFindPanelConstraintShow()
        } else {
            setFindPanelConstraintHide()
        }
    }

    /// Sets the find panel constraint to show the find panel.
    /// Can be animated using implicit animation.
    private func setFindPanelConstraintShow() {
        // Update the search bar's top to be equal to the view's top.
        findPanelVerticalConstraint.constant = view.safeAreaInsets.top
        findPanelVerticalConstraint.isActive = true
    }

    /// Sets the find panel constraint to hide the find panel.
    /// Can be animated using implicit animation.
    private func setFindPanelConstraintHide() {
        // Update the search bar's top anchor to be equal to it's negative height, hiding it above the view.

        // SwiftUI hates us. It refuses to move views outside of the safe are if they don't have the `.ignoresSafeArea`
        // modifier, but with that modifier on it refuses to allow it to be animated outside the safe area.
        // The only way I found to fix it was to multiply the height by 3 here.
        findPanelVerticalConstraint.constant = view.safeAreaInsets.top - (FindPanel.height * 3)
        findPanelVerticalConstraint.isActive = true
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
    func showFindPanel(animated: Bool = true) {
        guard !isShowingFindPanel else { return }
        isShowingFindPanel = true

        let updates: () -> Void = { [self] in
            // SwiftUI breaks things here, and refuses to return the correct `findPanel.fittingSize` so we
            // are forced to use a constant number.
            target?.findPanelWillShow(panelHeight: FindPanel.height)
            setFindPanelConstraintShow()
        }

        if animated {
            withAnimation(updates)
        } else {
            updates()
        }

        _ = findPanel?.becomeFirstResponder()
    }

    /// Hide the search bar
    func hideFindPanel(animated: Bool = true) {
        isShowingFindPanel = false
        _ = findPanel?.resignFirstResponder()

        let updates: () -> Void = { [self] in
            target?.findPanelWillHide(panelHeight: FindPanel.height)
            setFindPanelConstraintHide()
        }

        if animated {
            withAnimation(updates)
        } else {
            updates()
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
//        if let textViewController = target as? TextViewController,
//           let emphasizeAPI = target?.emphasizeAPI,
//           !emphasizeAPI.emphasizedRanges.isEmpty {
//            let activeIndex = emphasizeAPI.emphasizedRangeIndex ?? 0
//            let range = emphasizeAPI.emphasizedRanges[activeIndex].range
//            textViewController.textView.scrollToRange(range)
//            textViewController.setCursorPositions([CursorPosition(range: range)])
//        }
    }

    func findPanelOnCancel() {
        // Return focus to the editor and restore cursor
        if let textViewController = target as? TextViewController {
            // Get the current highlight range before doing anything else
//            var rangeToSelect: NSRange?
//            if let emphasizeAPI = target?.emphasizeAPI {
//                if !emphasizeAPI.emphasizedRanges.isEmpty {
//                    // Get the active highlight range
//                    let activeIndex = emphasizeAPI.emphasizedRangeIndex ?? 0
//                    rangeToSelect = emphasizeAPI.emphasizedRanges[activeIndex].range
//                }
//            }

            // Now hide the panel
            if isShowingFindPanel {
                hideFindPanel()
            }

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                // First make the text view first responder
                self.view.window?.makeFirstResponder(textViewController.textView)

                // If we had an active highlight, select it
//                if let rangeToSelect = rangeToSelect {
//                    // Set the selection first
//                    textViewController.textView.selectionManager.setSelectedRanges([rangeToSelect])
//                    textViewController.setCursorPositions([CursorPosition(range: rangeToSelect)])
//                    textViewController.textView.scrollToRange(rangeToSelect)
//
//                    // Then clear highlights after a short delay to ensure selection is set
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                        self.target?.emphasizeAPI?.removeEmphasizeLayers()
//                        textViewController.textView.needsDisplay = true
//                    }
//                } else if let currentPosition = textViewController.cursorPositions.first {
//                    // Otherwise ensure cursor is visible at last position
//                    textViewController.textView.scrollToRange(currentPosition.range)
//                    textViewController.textView.selectionManager.setSelectedRanges([currentPosition.range])
//                    self.target?.emphasizeAPI?.removeEmphasizeLayers()
//                }
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
//        if let textViewController = target as? TextViewController,
//           let emphasizeAPI = target?.emphasizeAPI,
//           !emphasizeAPI.emphasizedRanges.isEmpty {
//            let activeIndex = emphasizeAPI.emphasizedRangeIndex ?? 0
//            let range = emphasizeAPI.emphasizedRanges[activeIndex].range
//            textViewController.textView.scrollToRange(range)
//            textViewController.setCursorPositions([CursorPosition(range: range)])
//        }
    }

    func findPanelNextButtonClicked() {
        target?.emphasizeAPI?.highlightNext()
//        if let textViewController = target as? TextViewController,
//           let emphasizeAPI = target?.emphasizeAPI,
//           !emphasizeAPI.emphasizedRanges.isEmpty {
//            let activeIndex = emphasizeAPI.emphasizedRangeIndex ?? 0
//            let range = emphasizeAPI.emphasizedRanges[activeIndex].range
//            textViewController.textView.scrollToRange(range)
//            textViewController.setCursorPositions([CursorPosition(range: range)])
//        }
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
//        let currentActiveIndex = target.emphasizeAPI?.emphasizedRangeIndex ?? 0
//        let activeIndex = (target.emphasizeAPI?.emphasizedRanges.count == searchResults.count) ? 
//                         currentActiveIndex : 0

//        emphasizeAPI.emphasizeRanges(ranges: searchResults, activeIndex: activeIndex)
        
        // Only set cursor position if we're actively searching (not when clearing)
        if !query.isEmpty {
            // Always select the active highlight
//            target.setCursorPositions([CursorPosition(range: searchResults[activeIndex])])
        }
    }

    private func getNearestHighlightIndex(matchRanges: [NSRange]) -> Int? {
        // order the array as follows
        // Found: 1 -> 2 -> 3 -> 4
        // Cursor:       |
        // Result: 3 -> 4 -> 1 -> 2
        guard let cursorPosition = target?.cursorPositions.first else { return nil }
        let start = cursorPosition.range.location

        var left = 0
        var right = matchRanges.count - 1
        var bestIndex = -1
        var bestDiff = Int.max  // Stores the closest difference

        while left <= right {
            let mid = left + (right - left) / 2
            let midStart = matchRanges[mid].location
            let diff = abs(midStart - start)

            // If it's an exact match, return immediately
            if diff == 0 {
                return mid
            }

            // If this is the closest so far, update the best index
            if diff < bestDiff {
                bestDiff = diff
                bestIndex = mid
            }

            // Move left or right based on the cursor position
            if midStart < start {
                left = mid + 1
            } else {
                right = mid - 1
            }
        }

        return bestIndex >= 0 ? bestIndex : nil
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
