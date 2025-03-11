//
//  SearchViewController.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 3/10/25.
//

import AppKit

/// Creates a container controller for displaying and hiding a search bar with a content view.
final class SearchViewController: NSViewController {
    weak var target: SearchTarget?
    var childView: NSView
    var searchBar: SearchBar!

    private var searchBarVerticalConstraint: NSLayoutConstraint!

    private(set) public var isShowingSearchBar: Bool = false

    init(target: SearchTarget, childView: NSView) {
        self.target = target
        self.childView = childView
        super.init(nibName: nil, bundle: nil)
        self.searchBar = SearchBar(delegate: self)
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

        view.addSubview(searchBar)
        view.addSubview(childView)

        searchBarVerticalConstraint = searchBar.topAnchor.constraint(equalTo: view.topAnchor)

        NSLayoutConstraint.activate([
            // Constrain search bar
            searchBarVerticalConstraint,
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // Constrain child view
            childView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            childView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            childView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            childView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        if isShowingSearchBar { // Update constraints for initial state
            showSearchBar()
        } else {
            hideSearchBar()
        }
    }
}

// MARK: - Toggle Search Bar

extension SearchViewController {
    /// Toggle the search bar
    func toggleSearchBar() {
        if isShowingSearchBar {
            hideSearchBar()
        } else {
            showSearchBar()
        }
    }

    /// Show the search bar
    func showSearchBar() {
        isShowingSearchBar = true
        _ = searchBar?.searchField.becomeFirstResponder()
        withAnimation {
            // Update the search bar's top to be equal to the view's top.
            searchBarVerticalConstraint.constant = 0
            searchBarVerticalConstraint.isActive = true
        }
    }

    /// Hide the search bar
    func hideSearchBar() {
        isShowingSearchBar = false
        _ = searchBar?.searchField.resignFirstResponder()
        withAnimation {
            // Update the search bar's top anchor to be equal to it's negative height, hiding it above the view.
            searchBarVerticalConstraint.constant = -searchBar.fittingSize.height
            searchBarVerticalConstraint.isActive = true
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

extension SearchViewController: SearchBarDelegate {
    func searchBarOnSubmit() {
        target?.emphasizeAPI?.highlightNext()
        //        if let highlightedRange = target?.emphasizeAPI?.emphasizedRanges[target.emphasizeAPI?.emphasizedRangeIndex ?? 0] {
        //            target?.setCursorPositions([CursorPosition(range: highlightedRange.range)])
        //            target?.updateCursorPosition()
        //        }
    }

    func searchBarOnCancel() {
        if isShowingSearchBar {
            hideSearchBar()
        }
    }

    func searchBarDidUpdate(_ searchText: String) {
        searchFile(query: searchText)
    }

    func searchBarPrevButtonClicked() {
        target?.emphasizeAPI?.highlightPrevious()
        //        if let currentRange = textView.emphasizeAPI?.emphasizedRanges[(textView.emphasizeAPI?.emphasizedRangeIndex) ?? 0].range {
        //            textView.scrollToRange(currentRange)
        //        }
    }

    func searchBarNextButtonClicked() {
        target?.emphasizeAPI?.highlightNext()
        //        if let currentRange = textView.emphasizeAPI?.emphasizedRanges[(textView.emphasizeAPI?.emphasizedRangeIndex) ?? 0].range {
        //            textView.scrollToRange(currentRange)
        //            self.gutterView.needsDisplay = true
        //        }
    }

    func searchFile(query: String) {
        let searchOptions: NSRegularExpression.Options = smartCase(str: query) ? [] : [.caseInsensitive]
        let escapedQuery = NSRegularExpression.escapedPattern(for: query)

        guard let regex = try? NSRegularExpression(pattern: escapedQuery, options: searchOptions),
              let text = target?.text else {
            target?.emphasizeAPI?.removeEmphasizeLayers()
            return
        }

        let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        guard !matches.isEmpty else {
            target?.emphasizeAPI?.removeEmphasizeLayers()
            return
        }

        let searchResults = matches.map { $0.range }
        let bestHighlightIndex = getNearestHighlightIndex(matchRanges: searchResults) ?? 0
        print(searchResults.count)
        target?.emphasizeAPI?.emphasizeRanges(ranges: searchResults, activeIndex: 0)
        target?.setCursorPositions([CursorPosition(range: searchResults[bestHighlightIndex])])
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
}
