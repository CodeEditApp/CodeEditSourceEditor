//
//  FindViewController.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 3/10/25.
//

import AppKit
import CodeEditTextView

/// Creates a container controller for displaying and hiding a find panel with a content view.
final class FindViewController: NSViewController {
    weak var target: FindPanelTarget?
    var childView: NSView
    var findPanel: FindPanel!
    private var findMatches: [NSRange] = []
    private var currentFindMatchIndex: Int = 0
    private var findText: String = ""

    private var findPanelVerticalConstraint: NSLayoutConstraint!

    private(set) public var isShowingFindPanel: Bool = false

    init(target: FindPanelTarget, childView: NSView) {
        self.target = target
        self.childView = childView
        super.init(nibName: nil, bundle: nil)
        self.findPanel = FindPanel(delegate: self, textView: target as? NSView)

        // Add notification observer for text changes
        if let textViewController = target as? TextViewController {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(textDidChange),
                name: TextView.textDidChangeNotification,
                object: textViewController.textView
            )
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func textDidChange() {
        // Only update if we have find text
        if !findText.isEmpty {
            performFind(query: findText)
        }
    }

    private func performFind(query: String) {
        // Don't find if target or emphasisManager isn't ready
        guard let target = target else {
            findPanel.findDelegate?.findPanelUpdateMatchCount(0)
            findMatches = []
            currentFindMatchIndex = 0
            return
        }

        // Clear emphases and return if query is empty
        if query.isEmpty {
            findPanel.findDelegate?.findPanelUpdateMatchCount(0)
            findMatches = []
            currentFindMatchIndex = 0
            return
        }

        let findOptions: NSRegularExpression.Options = smartCase(str: query) ? [] : [.caseInsensitive]
        let escapedQuery = NSRegularExpression.escapedPattern(for: query)

        guard let regex = try? NSRegularExpression(pattern: escapedQuery, options: findOptions) else {
            findPanel.findDelegate?.findPanelUpdateMatchCount(0)
            findMatches = []
            currentFindMatchIndex = 0
            return
        }

        let text = target.text
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))

        findMatches = matches.map { $0.range }
        findPanel.findDelegate?.findPanelUpdateMatchCount(findMatches.count)

        // Find the nearest match to the current cursor position
        currentFindMatchIndex = getNearestEmphasisIndex(matchRanges: findMatches) ?? 0
    }

    private func addEmphases() {
        guard let target = target,
              let emphasisManager = target.emphasisManager else { return }

        // Clear existing emphases
        emphasisManager.removeEmphases(for: "find")

        // Create emphasis with the nearest match as active
        let emphases = findMatches.enumerated().map { index, range in
            Emphasis(
                range: range,
                style: .standard,
                flash: false,
                inactive: index != currentFindMatchIndex,
                select: index == currentFindMatchIndex
            )
        }

        // Add all emphases
        emphasisManager.addEmphases(emphases, for: "find")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        super.loadView()

        // Set up the `childView` as a subview of our view. Constrained to all edges, except the top is constrained to
        // the find panel's bottom
        // The find panel is constrained to the top of the view.
        // The find panel's top anchor when hidden, is equal to it's negated height hiding it above the view's contents.
        // When visible, it's set to 0.

        view.clipsToBounds = false
        view.addSubview(findPanel)
        view.addSubview(childView)

        // Ensure find panel is always on top
        findPanel.wantsLayer = true
        findPanel.layer?.zPosition = 1000

        findPanelVerticalConstraint = findPanel.topAnchor.constraint(equalTo: view.topAnchor)

        NSLayoutConstraint.activate([
            // Constrain find panel
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
        // Update the find panel's top to be equal to the view's top.
        findPanelVerticalConstraint.constant = view.safeAreaInsets.top
        findPanelVerticalConstraint.isActive = true
    }

    /// Sets the find panel constraint to hide the find panel.
    /// Can be animated using implicit animation.
    private func setFindPanelConstraintHide() {
        // Update the find panel's top anchor to be equal to it's negative height, hiding it above the view.

        // SwiftUI hates us. It refuses to move views outside of the safe are if they don't have the `.ignoresSafeArea`
        // modifier, but with that modifier on it refuses to allow it to be animated outside the safe area.
        // The only way I found to fix it was to multiply the height by 3 here.
        findPanelVerticalConstraint.constant = view.safeAreaInsets.top - (FindPanel.height * 3)
        findPanelVerticalConstraint.isActive = true
    }
}

// MARK: - Toggle find panel

extension FindViewController {
    /// Toggle the find panel
    func toggleFindPanel() {
        if isShowingFindPanel {
            hideFindPanel()
        } else {
            showFindPanel()
        }
    }

    /// Show the find panel
    func showFindPanel(animated: Bool = true) {
        if isShowingFindPanel {
            // If panel is already showing, just focus the text field
            _ = findPanel?.becomeFirstResponder()
            return
        }

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
        findPanel?.addEventMonitor()
    }

    /// Hide the find panel
    func hideFindPanel(animated: Bool = true) {
        isShowingFindPanel = false
        _ = findPanel?.resignFirstResponder()
        findPanel?.removeEventMonitor()

        let updates: () -> Void = { [self] in
            target?.findPanelWillHide(panelHeight: FindPanel.height)
            setFindPanelConstraintHide()
        }

        if animated {
            withAnimation(updates)
        } else {
            updates()
        }

        // Set first responder back to text view
        if let textViewController = target as? TextViewController {
            _ = textViewController.textView.window?.makeFirstResponder(textViewController.textView)
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

// MARK: - Find Panel Delegate

extension FindViewController: FindPanelDelegate {
    func findPanelOnSubmit() {
        findPanelNextButtonClicked()
    }

    func findPanelOnCancel() {
        if isShowingFindPanel {
            hideFindPanel()
        }
    }

    func findPanelDidUpdate(_ text: String) {
        // Check if this update was triggered by a return key without shift
        if let currentEvent = NSApp.currentEvent,
           currentEvent.type == .keyDown,
           currentEvent.keyCode == 36, // Return key
           !currentEvent.modifierFlags.contains(.shift) {
            return // Skip find for regular return key
        }

        // Only perform find if we're focusing the text view
        if let textViewController = target as? TextViewController,
           textViewController.textView.window?.firstResponder === textViewController.textView {
            // If the text view has focus, just clear visual emphases but keep matches in memory
            target?.emphasisManager?.removeEmphases(for: "find")
            // Re-add the current active emphasis without visual emphasis
            if let emphases = target?.emphasisManager?.getEmphases(for: "find"),
               let activeEmphasis = emphases.first(where: { !$0.inactive }) {
                target?.emphasisManager?.addEmphasis(
                    Emphasis(
                        range: activeEmphasis.range,
                        style: .standard,
                        flash: false,
                        inactive: false,
                        select: true
                    ),
                    for: "find"
                )
            }
            return
        }

        // Clear existing emphases before performing new find
        target?.emphasisManager?.removeEmphases(for: "find")
        find(text: text)
    }

    func findPanelPrevButtonClicked() {
        guard let textViewController = target as? TextViewController,
              let emphasisManager = target?.emphasisManager else { return }

        // Check if there are any matches
        if findMatches.isEmpty {
            return
        }

        // Update to previous match
        let oldIndex = currentFindMatchIndex
        currentFindMatchIndex = (currentFindMatchIndex - 1 + findMatches.count) % findMatches.count

        // Show bezel notification if we cycled from first to last match
        if oldIndex == 0 && currentFindMatchIndex == findMatches.count - 1 {
            BezelNotification.show(
                symbolName: "arrow.trianglehead.bottomleft.capsulepath.clockwise",
                over: textViewController.textView
            )
        }

        // If the text view has focus, show a flash animation for the current match
        if textViewController.textView.window?.firstResponder === textViewController.textView {
            let newActiveRange = findMatches[currentFindMatchIndex]

            // Clear existing emphases before adding the flash
            emphasisManager.removeEmphases(for: "find")

            emphasisManager.addEmphasis(
                Emphasis(
                    range: newActiveRange,
                    style: .standard,
                    flash: true,
                    inactive: false,
                    select: true
                ),
                for: "find"
            )

            return
        }

        // Create updated emphases with new active state
        let updatedEmphases = findMatches.enumerated().map { index, range in
            Emphasis(
                range: range,
                style: .standard,
                flash: false,
                inactive: index != currentFindMatchIndex,
                select: index == currentFindMatchIndex
            )
        }

        // Replace all emphases to update state
        emphasisManager.replaceEmphases(updatedEmphases, for: "find")
    }

    func findPanelNextButtonClicked() {
        guard let textViewController = target as? TextViewController,
              let emphasisManager = target?.emphasisManager else { return }

        // Check if there are any matches
        if findMatches.isEmpty {
            // Show "no matches" bezel notification and play beep
            NSSound.beep()
            BezelNotification.show(
                symbolName: "arrow.down.to.line",
                over: textViewController.textView
            )
            return
        }

        // Update to next match
        let oldIndex = currentFindMatchIndex
        currentFindMatchIndex = (currentFindMatchIndex + 1) % findMatches.count

        // Show bezel notification if we cycled from last to first match
        if oldIndex == findMatches.count - 1 && currentFindMatchIndex == 0 {
            BezelNotification.show(
                symbolName: "arrow.triangle.capsulepath",
                over: textViewController.textView
            )
        }

        // If the text view has focus, show a flash animation for the current match
        if textViewController.textView.window?.firstResponder === textViewController.textView {
            let newActiveRange = findMatches[currentFindMatchIndex]

            // Clear existing emphases before adding the flash
            emphasisManager.removeEmphases(for: "find")

            emphasisManager.addEmphasis(
                Emphasis(
                    range: newActiveRange,
                    style: .standard,
                    flash: true,
                    inactive: false,
                    select: true
                ),
                for: "find"
            )

            return
        }

        // Create updated emphases with new active state
        let updatedEmphases = findMatches.enumerated().map { index, range in
            Emphasis(
                range: range,
                style: .standard,
                flash: false,
                inactive: index != currentFindMatchIndex,
                select: index == currentFindMatchIndex
            )
        }

        // Replace all emphases to update state
        emphasisManager.replaceEmphases(updatedEmphases, for: "find")
    }

    func find(text: String) {
        findText = text
        performFind(query: text)
        addEmphases()
    }

    private func getNearestEmphasisIndex(matchRanges: [NSRange]) -> Int? {
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

    // Only re-find the part of the file that changed upwards
    private func reFind() { }

    // Returns true if string contains uppercase letter
    // used for: ignores letter case if the find text is all lowercase
    private func smartCase(str: String) -> Bool {
        return str.range(of: "[A-Z]", options: .regularExpression) != nil
    }

    func findPanelUpdateMatchCount(_ count: Int) {
        findPanel.updateMatchCount(count)
    }

    func findPanelClearEmphasis() {
        target?.emphasisManager?.removeEmphases(for: "find")
    }
}
