//
//  SearchBar.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 3/10/25.
//

import AppKit

protocol SearchBarDelegate: AnyObject {
    func searchBarOnSubmit()
    func searchBarOnCancel()
    func searchBarDidUpdate(_ searchText: String)
    func searchBarPrevButtonClicked()
    func searchBarNextButtonClicked()
}

/// A control for searching a document and navigating results.
final class SearchBar: NSStackView {
    weak var searchDelegate: SearchBarDelegate?

    var searchField: NSTextField!
    var prevButton: NSButton!
    var nextButton: NSButton!

    init(delegate: SearchBarDelegate?) {
        super.init(frame: .zero)

        self.searchDelegate = delegate

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

        self.orientation = .horizontal
        self.spacing = 8
        self.edgeInsets = NSEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        self.translatesAutoresizingMaskIntoConstraints = false

        self.addView(searchField, in: .leading)
        self.addView(prevButton, in: .trailing)
        self.addView(nextButton, in: .trailing)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(searchFieldUpdated(_:)),
            name: NSControl.textDidChangeNotification,
            object: searchField
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Hide the search bar when escape is pressed
    override func cancelOperation(_ sender: Any?) {
        searchDelegate?.searchBarOnCancel()
    }

    // MARK: - Delegate Messaging

    @objc func searchFieldUpdated(_ notification: Notification) {
        guard let searchField = notification.object as? NSTextField else { return }
        searchDelegate?.searchBarDidUpdate(searchField.stringValue)
    }

    @objc func onSubmit() {
        searchDelegate?.searchBarOnSubmit()
    }

    @objc func prevButtonClicked() {
        searchDelegate?.searchBarPrevButtonClicked()
    }

    @objc func nextButtonClicked() {
        searchDelegate?.searchBarNextButtonClicked()
    }
}
