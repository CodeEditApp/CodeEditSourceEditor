//
//  FindPanelView.swift
//  CodeEditSourceEditor
//
//  Created by Austin Condiff on 3/12/25.
//

import SwiftUI
import AppKit

struct FindPanelView: View {
    @Environment(\.controlActiveState) var activeState
    @ObservedObject var viewModel: FindPanelViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 5) {
            PanelTextField(
                "Search...",
                text: $viewModel.findText,
                leadingAccessories: {
                    Image(systemName: "magnifyingglass")
                        .padding(.leading, 8)
                        .foregroundStyle(activeState == .inactive ? .tertiary : .secondary)
                        .font(.system(size: 12))
                        .frame(width: 16, height: 20)
                },
                helperText: viewModel.findText.isEmpty
                ? nil
                : "\(viewModel.matchCount) \(viewModel.matchCount == 1 ? "match" : "matches")",
                clearable: true
            )
            .focused($isFocused)
            .onChange(of: viewModel.findText) { newValue in
                viewModel.onFindTextChange(newValue)
            }
            .onChange(of: viewModel.isFocused) { newValue in
                isFocused = newValue
                if !newValue {
                    viewModel.removeEmphasis()
                }
            }
            .onChange(of: isFocused) { newValue in
                viewModel.setFocus(newValue)
            }
            .onSubmit {
                viewModel.onSubmit()
            }
            HStack(spacing: 4) {
                ControlGroup {
                    Button(action: viewModel.prevButtonClicked) {
                        Image(systemName: "chevron.left")
                            .opacity(viewModel.matchCount == 0 ? 0.33 : 1)
                            .padding(.horizontal, 5)
                    }
                    .disabled(viewModel.matchCount == 0)
                    Divider()
                        .overlay(Color(nsColor: .tertiaryLabelColor))
                    Button(action: viewModel.nextButtonClicked) {
                        Image(systemName: "chevron.right")
                            .opacity(viewModel.matchCount == 0 ? 0.33 : 1)
                            .padding(.horizontal, 5)
                    }
                    .disabled(viewModel.matchCount == 0)
                }
                .controlGroupStyle(PanelControlGroupStyle())
                .fixedSize()
                Button(action: viewModel.onDismiss) {
                    Text("Done")
                        .padding(.horizontal, 5)
                }
                .buttonStyle(PanelButtonStyle())
            }
        }
        .padding(.horizontal, 5)
        .frame(height: FindPanel.height)
        .background(.bar)
    }
}
