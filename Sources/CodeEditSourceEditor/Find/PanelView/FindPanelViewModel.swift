//
//  FindPanelViewModel.swift
//  CodeEditSourceEditor
//
//  Created by Austin Condiff on 3/12/25.
//

import SwiftUI
import Combine

class FindPanelViewModel: ObservableObject {
    @Published var findText: String = ""
    @Published var matchCount: Int = 0
    @Published var isFocused: Bool = false

    private weak var delegate: FindPanelDelegate?

    init(delegate: FindPanelDelegate?) {
        self.delegate = delegate
    }

    func startObservingFindText() {
        if !findText.isEmpty {
            delegate?.findPanelDidUpdate(findText)
        }
    }

    func onFindTextChange(_ text: String) {
        delegate?.findPanelDidUpdate(text)
    }

    func onSubmit() {
        delegate?.findPanelOnSubmit()
    }

    func onDismiss() {
        delegate?.findPanelOnDismiss()
    }

    func setFocus(_ focused: Bool) {
        isFocused = focused
        if focused && !findText.isEmpty {
            // Restore emphases when focus is regained and we have search text
            delegate?.findPanelDidUpdate(findText)
        }
    }

    func updateMatchCount(_ count: Int) {
        matchCount = count
    }

    func removeEmphasis() {
        delegate?.findPanelClearEmphasis()
    }

    func prevButtonClicked() {
        delegate?.findPanelPrevButtonClicked()
    }

    func nextButtonClicked() {
        delegate?.findPanelNextButtonClicked()
    }
}
