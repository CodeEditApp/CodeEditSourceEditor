//
//  FindPanelView.swift
//  CodeEditSourceEditor
//
//  Created by Austin Condiff on 3/12/25.
//

import SwiftUI
import AppKit
import CodeEditSymbols

/// A SwiftUI view that provides a find and replace interface for the text editor.
///
/// The `FindPanelView` is the main container view for the find and replace functionality. It manages:
/// - The find/replace mode switching
/// - Focus management between find and replace fields
/// - Panel height adjustments based on mode
/// - Search text changes and match highlighting
/// - Case sensitivity and wrap-around settings
///
/// The view automatically adapts its layout based on available space using `ViewThatFits`, providing
/// both a full and condensed layout option.
struct FindPanelView: View {
    /// Represents the current focus state of the find panel
    enum FindPanelFocus: Equatable {
        /// The find text field is focused
        case find
        /// The replace text field is focused
        case replace
    }

    @Environment(\.controlActiveState) var activeState
    @ObservedObject var viewModel: FindPanelViewModel
    @State private var findModePickerWidth: CGFloat = 1.0

    @FocusState private var focus: FindPanelFocus?

    var body: some View {
        ViewThatFits {
            FindPanelContent(
                viewModel: viewModel,
                focus: $focus,
                findModePickerWidth: $findModePickerWidth,
                condensed: false
            )
            FindPanelContent(
                viewModel: viewModel,
                focus: $focus,
                findModePickerWidth: $findModePickerWidth,
                condensed: true
            )
        }
        .padding(.horizontal, 5)
        .frame(height: viewModel.panelHeight)
        .background(.bar)
        .onChange(of: focus) { newValue in
            viewModel.isFocused = newValue != nil
        }
        .onChange(of: viewModel.findText) { _ in
            viewModel.findTextDidChange()
        }
        .onChange(of: viewModel.wrapAround) { _ in
            viewModel.find()
        }
        .onChange(of: viewModel.matchCase) { _ in
            viewModel.find()
        }
        .onChange(of: viewModel.isFocused) { newValue in
            if newValue {
                if focus == nil {
                    focus = .find
                }
                if !viewModel.findText.isEmpty {
                    // Restore emphases when focus is regained and we have search text
                    viewModel.addMatchEmphases(flashCurrent: false)
                }
            } else {
                viewModel.clearMatchEmphases()
            }
        }
    }
}

/// A preference key used to track the width of the find mode picker
private struct FindModePickerWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
