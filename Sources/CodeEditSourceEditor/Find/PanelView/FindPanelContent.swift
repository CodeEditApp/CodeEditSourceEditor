//
//  FindPanelContent.swift
//  CodeEditSourceEditor
//
//  Created by Austin Condiff on 5/2/25.
//

import SwiftUI

struct FindPanelContent: View {
    @ObservedObject var viewModel: FindPanelViewModel
    @FocusState.Binding var focus: FindPanelView.FindPanelFocus?
    var findModePickerWidth: Binding<CGFloat>
    var condensed: Bool

    var body: some View {
        HStack(spacing: 5) {
            VStack(alignment: .leading, spacing: 4) {
                FindSearchField(
                    viewModel: viewModel,
                    focus: $focus,
                    findModePickerWidth: findModePickerWidth,
                    condensed: condensed
                )
                if viewModel.mode == .replace {
                    ReplaceSearchField(
                        viewModel: viewModel,
                        focus: $focus,
                        findModePickerWidth: findModePickerWidth,
                        condensed: condensed
                    )
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                FindControls(viewModel: viewModel, condensed: condensed)
                if viewModel.mode == .replace {
                    Spacer(minLength: 0)
                    ReplaceControls(viewModel: viewModel, condensed: condensed)
                }
            }
            .fixedSize()
        }
    }
}
