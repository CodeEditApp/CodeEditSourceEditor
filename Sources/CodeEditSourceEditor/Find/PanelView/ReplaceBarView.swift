//
//  ReplaceBarView.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 4/18/25.
//

import SwiftUI

struct ReplaceBarView: View {
    @ObservedObject var viewModel: FindPanelViewModel
    @FocusState.Binding var focus: FindPanelView.FindPanelFocus?
    @Binding var findModePickerWidth: CGFloat

    var body: some View {
        HStack(spacing: 5) {
            PanelTextField(
                "Text",
                text: $viewModel.replaceText,
                leadingAccessories: {
                    HStack(spacing: 0) {
                        Image(systemName: "pencil")
                            .foregroundStyle(.secondary)
                            .padding(.leading, 8)
                            .padding(.trailing, 5)
                        Text("With")
                    }
                    .frame(width: findModePickerWidth, alignment: .leading)
                    Divider()
                },
                clearable: true
            )
            .controlSize(.small)
            .focused($focus, equals: .replace)
            HStack(spacing: 4) {
                ControlGroup {
                    Button {
                        viewModel.replace(all: false)
                    } label: {
                        Text("Replace")
                            .opacity(
                                !viewModel.isFocused
                                || viewModel.findText.isEmpty
                                || viewModel.matchCount == 0 ? 0.33 : 1
                            )
//                            .frame(width: viewModel.findControlsWidth/2 - 12 - 0.5)
                    }
                    // TODO: disable if there is not an active match
                    .disabled(
                        !viewModel.isFocused
                        || viewModel.findText.isEmpty
                        || viewModel.matchCount == 0
                    )
                    Divider()
                        .overlay(Color(nsColor: .tertiaryLabelColor))
                    Button {
                        viewModel.replace(all: true)
                    } label: {
                        Text("All")
                            .opacity(viewModel.findText.isEmpty || viewModel.matchCount == 0 ? 0.33 : 1)
//                            .frame(width: viewModel.findControlsWidth/2 - 12 - 0.5)
                    }
                    .disabled(viewModel.findText.isEmpty || viewModel.matchCount == 0)
                }
                .controlGroupStyle(PanelControlGroupStyle())
                .fixedSize()
            }
        }
        .padding(.horizontal, 5)
    }
}
