//
//  FindPanelView.swift
//  CodeEditSourceEditor
//
//  Created by Austin Condiff on 3/12/25.
//

import SwiftUI
import AppKit
import CodeEditSymbols

struct FindPanelView: View {
    enum FindPanelFocus: Equatable {
        case find
        case replace
    }

    @Environment(\.controlActiveState) var activeState
    @ObservedObject var viewModel: FindPanelViewModel
    @State private var findModePickerWidth: CGFloat = 1.0

    @FocusState private var focus: FindPanelFocus?

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            FindBarView(viewModel: viewModel, focus: $focus, findModePickerWidth: $findModePickerWidth)
            if viewModel.mode == .replace {
                ReplaceBarView(viewModel: viewModel, focus: $focus, findModePickerWidth: $findModePickerWidth)
            }
        }
        .frame(height: viewModel.panelHeight)
        .background(.bar)
        .onChange(of: focus) { newValue in
            viewModel.isFocused = newValue != nil
        }
        .onChange(of: viewModel.findText) { _ in
            viewModel.findTextDidChange()
        }
//        .onChange(of: viewModel.mode) { newMode in
            //
//        }
//        .onChange(of: viewModel.wrapAround) { newValue in
//            viewModel.onWrapAroundChange(newValue)
//        }
//        .onChange(of: viewModel.matchCase) { newValue in
//            viewModel.onMatchCaseChange(newValue)
//        }
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

private struct FindModePickerWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
