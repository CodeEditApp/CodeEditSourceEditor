//
//  FindPanelViewModel.swift
//  CodeEditSourceEditor
//
//  Created by Austin Condiff on 3/12/25.
//

import SwiftUI
import Combine

class FindPanelViewModel: ObservableObject {
    weak var delegate: FindPanelDelegate?
    @Published var isFocused: Bool = false
    @Published var searchText: String = ""
    @Published var matchCount: Int = 0
    private var cancellables = Set<AnyCancellable>()

    init(delegate: FindPanelDelegate?) {
        self.delegate = delegate
    }

    func startObservingSearchText() {
        // Set up observer for searchText changes
        $searchText
            .sink { [weak self] newValue in
                self?.delegate?.findPanelDidUpdate(newValue)
            }
            .store(in: &cancellables)
    }

    func onSubmit() {
        delegate?.findPanelOnSubmit()
    }

    func onCancel() {
        setFocus(false)  // Remove focus from search field
        delegate?.findPanelOnCancel()  // Call delegate first
        searchText = ""  // Clear the search text last
    }

    func prevButtonClicked() {
        delegate?.findPanelPrevButtonClicked()
    }

    func nextButtonClicked() {
        delegate?.findPanelNextButtonClicked()
    }

    func setFocus(_ focused: Bool) {
        isFocused = focused
    }

    func updateMatchCount(_ count: Int) {
        matchCount = count
    }

    func removeEmphasis() {
        delegate?.findPanelClearEmphasis()
    }
}
