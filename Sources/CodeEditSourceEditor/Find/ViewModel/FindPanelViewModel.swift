//
//  FindPanelViewModel.swift
//  CodeEditSourceEditor
//
//  Created by Austin Condiff on 3/12/25.
//

import SwiftUI
import Combine
import CodeEditTextView

class FindPanelViewModel: ObservableObject {
    weak var target: FindPanelTarget?
    var dismiss: (() -> Void)?

    @Published var findMatches: [NSRange] = []
    @Published var currentFindMatchIndex: Int?
    @Published var isShowingFindPanel: Bool = false

    @Published var findText: String = ""
    @Published var replaceText: String = ""
    @Published var mode: FindPanelMode = .find

    @Published var isFocused: Bool = false

    @Published var matchCase: Bool = false
    @Published var wrapAround: Bool = true

    var panelHeight: CGFloat {
        return mode == .replace ? 56 : 28
    }

    var matchCount: Int {
        findMatches.count
    }

    private var cancellables: Set<AnyCancellable> = []

    init(target: FindPanelTarget) {
        self.target = target

        // Add notification observer for text changes
        if let textViewController = target as? TextViewController {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(textDidChange),
                name: TextView.textDidChangeNotification,
                object: textViewController.textView
            )
        }

        $mode
            .sink { newMode in
                self.target?.findPanelModeDidChange(to: newMode, panelHeight: self.panelHeight)
            }
            .store(in: &cancellables)
    }

    // MARK: - Update Matches

    func updateMatches(_ newMatches: [NSRange]) {
        findMatches = newMatches
        currentFindMatchIndex = newMatches.isEmpty ? nil : 0
    }

    // MARK: - Text Listeners

    @objc private func textDidChange() {
        // Only update if we have find text
        if !findText.isEmpty {
            find()
        }
    }

    func findTextDidChange() {
        // Check if this update was triggered by a return key without shift
        if let currentEvent = NSApp.currentEvent,
           currentEvent.type == .keyDown,
           currentEvent.keyCode == 36, // Return key
           !currentEvent.modifierFlags.contains(.shift) {
            return // Skip find for regular return key
        }

        // If the textview is first responder, exit fast
        if target?.findPanelTargetView.window?.firstResponder === target?.findPanelTargetView {
            // If the text view has focus, just clear visual emphases but keep our find matches
            target?.emphasisManager?.removeEmphases(for: EmphasisGroup.find)
            return
        }

        // Clear existing emphases before performing new find
        target?.emphasisManager?.removeEmphases(for: EmphasisGroup.find)
        find()
    }
}
