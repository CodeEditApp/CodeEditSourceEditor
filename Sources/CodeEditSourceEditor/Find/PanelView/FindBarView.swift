//
//  FindBarView.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 4/18/25.
//

import SwiftUI

struct FindBarView: View {
    @ObservedObject var viewModel: FindPanelViewModel
    @FocusState.Binding var focus: FindPanelView.FindPanelFocus?
    @Binding var findModePickerWidth: CGFloat

    var body: some View {
        HStack(spacing: 5) {
            PanelTextField(
                "Text",
                text: $viewModel.findText,
                leadingAccessories: {
                    FindModePicker(
                        mode: $viewModel.mode,
                        wrapAround: $viewModel.wrapAround
                    )
                    .background(GeometryReader { geometry in
                        Color.clear.onAppear {
                            findModePickerWidth = geometry.size.width
                        }
                        .onChange(of: geometry.size.width) { newWidth in
                            findModePickerWidth = newWidth
                        }
                    })
                    .focusable(false)
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
            .focused($focus, equals: .find)
            .onSubmit {
                viewModel.moveToNextMatch()
            }
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
//            .background(GeometryReader { geometry in
//                Color.clear.onAppear {
//                    findControlsWidth = geometry.size.width
//                }
//                .onChange(of: geometry.size.width) { newWidth in
//                    findControlsWidth = newWidth
//                }
//            })
        }
        .padding(.horizontal, 5)
    }
}
