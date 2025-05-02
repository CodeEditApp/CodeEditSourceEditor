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
        HStack(spacing: 5) {
            VStack(alignment: .leading, spacing: 4) {
                FindSearchField(viewModel: viewModel, focus: $focus, findModePickerWidth: $findModePickerWidth)
                if viewModel.mode == .replace {
                    ReplaceSearchField(viewModel: viewModel, focus: $focus, findModePickerWidth: $findModePickerWidth)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                doneNextControls
                if viewModel.mode == .replace {
                    Spacer(minLength: 0)
                    replaceControls
                }
            }
            .fixedSize()
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

    @ViewBuilder private var doneNextControls: some View {
        HStack(spacing: 4) {
            ControlGroup {
                Button {
                    viewModel.moveToPreviousMatch()
                } label: {
                    Image(systemName: "chevron.left")
                        .opacity(viewModel.matchCount == 0 ? 0.33 : 1)
                        .padding(.horizontal, 5)
                }
                .disabled(viewModel.matchCount == 0)
                Divider()
                    .overlay(Color(nsColor: .tertiaryLabelColor))
                Button {
                    viewModel.moveToNextMatch()
                } label: {
                    Image(systemName: "chevron.right")
                        .opacity(viewModel.matchCount == 0 ? 0.33 : 1)
                        .padding(.horizontal, 5)
                }
                .disabled(viewModel.matchCount == 0)
            }
            .controlGroupStyle(PanelControlGroupStyle())
            .fixedSize()
            Button {
                viewModel.dismiss?()
            } label: {
                Text("Done")
                    .padding(.horizontal, 5)
            }
            .buttonStyle(PanelButtonStyle())
        }
    }

    @ViewBuilder private var replaceControls: some View {
        HStack(spacing: 4) {
            ControlGroup {
                Button {
                    viewModel.replace()
                } label: {
                    Text("Replace")
                        .opacity(
                            !viewModel.isFocused
                            || viewModel.findText.isEmpty
                            || viewModel.matchCount == 0 ? 0.33 : 1
                        )
                }
                // TODO: disable if there is not an active match
                .disabled(
                    !viewModel.isFocused
                    || viewModel.findText.isEmpty
                    || viewModel.matchCount == 0
                )
                .frame(maxWidth: .infinity)

                Divider().overlay(Color(nsColor: .tertiaryLabelColor))

                Button {
                    viewModel.replaceAll()
                } label: {
                    Text("All")
                        .opacity(viewModel.findText.isEmpty || viewModel.matchCount == 0 ? 0.33 : 1)
                }
                .disabled(viewModel.findText.isEmpty || viewModel.matchCount == 0)
                .frame(maxWidth: .infinity)
            }
            .controlGroupStyle(PanelControlGroupStyle())
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct FindModePickerWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
