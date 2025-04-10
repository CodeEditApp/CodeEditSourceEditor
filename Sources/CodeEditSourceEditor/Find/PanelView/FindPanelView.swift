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
    @Environment(\.controlActiveState) var activeState
    @ObservedObject var viewModel: FindPanelViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 5) {
                PanelTextField(
                    "Text",
                    text: $viewModel.findText,
                    leadingAccessories: {
                        FindModePicker(
                            mode: $viewModel.mode,
                            wrapAround: $viewModel.wrapAround,
                            onToggleWrapAround: viewModel.toggleWrapAround
                        )
                        .background(GeometryReader { geometry in
                            Color.clear.onAppear {
                                viewModel.findModePickerWidth = geometry.size.width
                            }
                            .onChange(of: geometry.size.width) { newWidth in
                                viewModel.findModePickerWidth = newWidth
                            }
                        })
                        Divider()
                    },
                    trailingAccessories: {
                        Divider()
                        Toggle(isOn: $viewModel.matchCase, label: {
                            Image(systemName: "textformat")
                                .font(.system(
                                    size: 11,
                                    weight: viewModel.matchCase ? .bold : .medium
                                ))
                                .foregroundStyle(
                                    Color(nsColor: viewModel.matchCase
                                       ? .controlAccentColor
                                       : .labelColor
                                    )
                                )
                                .frame(width: 30, height: 20)
                        })
                        .toggleStyle(.icon)
                    },
                    helperText: viewModel.findText.isEmpty
                    ? nil
                    : "\(viewModel.matchCount) \(viewModel.matchCount == 1 ? "match" : "matches")",
                    clearable: true
                )
                .controlSize(.small)
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
                .background(GeometryReader { geometry in
                    Color.clear.onAppear {
                        viewModel.findControlsWidth = geometry.size.width
                    }
                    .onChange(of: geometry.size.width) { newWidth in
                        viewModel.findControlsWidth = newWidth
                    }
                })
            }
            .padding(.horizontal, 5)
            if viewModel.mode == .replace {
                HStack(spacing: 5) {
                    PanelTextField(
                        "Text",
                        text: $viewModel.replaceText,
                        leadingAccessories: {
                            HStack(spacing: 0) {
                                Image(systemName: "pencil")
                                    .padding(.leading, 8)
                                    .padding(.trailing, 5)
                                Text("With")
                            }
                            .frame(width: viewModel.findModePickerWidth, alignment: .leading)
                            Divider()
                        },
                        helperText: viewModel.findText.isEmpty
                        ? nil
                        : "\(viewModel.matchCount) \(viewModel.matchCount == 1 ? "match" : "matches")",
                        clearable: true
                    )
                    .controlSize(.small)
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
                                Text("Replace")
                                    .opacity(viewModel.matchCount == 0 ? 0.33 : 1)
                                    .frame(width: viewModel.findControlsWidth/2 - 12 - 0.5)
                            }
                            .disabled(viewModel.matchCount == 0)
                            Divider()
                                .overlay(Color(nsColor: .tertiaryLabelColor))
                            Button(action: viewModel.nextButtonClicked) {
                                Text("All")
                                    .opacity(viewModel.matchCount == 0 ? 0.33 : 1)
                                    .frame(width: viewModel.findControlsWidth/2 - 12 - 0.5)
                            }
                            .disabled(viewModel.matchCount == 0)
                        }
                        .controlGroupStyle(PanelControlGroupStyle())
                        .fixedSize()
                    }
                }
                .padding(.horizontal, 5)
            }
        }
        .frame(height: viewModel.mode == .replace ? FindPanel.height * 2 : FindPanel.height)
        .background(.bar)
    }
}

private struct FindModePickerWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
