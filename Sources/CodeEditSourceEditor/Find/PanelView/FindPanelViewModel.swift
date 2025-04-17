//
//  FindPanelViewModel.swift
//  CodeEditSourceEditor
//
//  Created by Austin Condiff on 3/12/25.
//

import SwiftUI
import Combine

enum FindPanelMode: CaseIterable {
    case find
    case replace

    var displayName: String {
        switch self {
        case .find:
            return "Find"
        case .replace:
            return "Replace"
        }
    }
}

class FindPanelViewModel: ObservableObject {
    @Published var findText: String = ""
    @Published var replaceText: String = ""
    @Published var mode: FindPanelMode = .find
    @Published var wrapAround: Bool = true
    @Published var matchCount: Int = 0
    @Published var isFocused: Bool = false
    @Published var findModePickerWidth: CGFloat = 0
    @Published var findControlsWidth: CGFloat = 0
    @Published var matchCase: Bool = false

    var panelHeight: CGFloat {
        return mode == .replace ? 56 : 28
    }

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

    func onReplaceTextChange(_ text: String) {
        delegate?.findPanelDidUpdateReplaceText(text)
    }

    func onModeChange(_ mode: FindPanelMode) {
        delegate?.findPanelDidUpdateMode(mode)
    }

    func onWrapAroundChange(_ wrapAround: Bool) {
        delegate?.findPanelDidUpdateWrapAround(wrapAround)
    }

    func onMatchCaseChange(_ matchCase: Bool) {
        delegate?.findPanelDidUpdateMatchCase(matchCase)
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

    func replaceButtonClicked() {
        delegate?.findPanelReplaceButtonClicked()
    }

    func replaceAllButtonClicked() {
        delegate?.findPanelReplaceAllButtonClicked()
    }

    func toggleWrapAround() {
        wrapAround.toggle()
        delegate?.findPanelDidUpdateWrapAround(wrapAround)
    }
}
