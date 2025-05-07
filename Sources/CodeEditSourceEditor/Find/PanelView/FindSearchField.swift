//
//  FindSearchField.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 4/18/25.
//

import SwiftUI

struct FindSearchField: View {
    @ObservedObject var viewModel: FindPanelViewModel
    @FocusState.Binding var focus: FindPanelView.FindPanelFocus?
    @Binding var findModePickerWidth: CGFloat
    var condensed: Bool

    private var helperText: String? {
        if viewModel.findText.isEmpty {
            nil
        } else if condensed {
            "\(viewModel.matchCount)"
        } else {
            "\(viewModel.matchCount) \(viewModel.matchCount == 1 ? "match" : "matches")"
        }
    }

    var body: some View {
        PanelTextField(
            "Text",
            text: $viewModel.findText,
            leadingAccessories: {
                if condensed {
                    Color.clear
                        .frame(width: 12, height: 12)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 8)
                        .overlay(alignment: .leading) {
                            FindModePicker(
                                mode: $viewModel.mode,
                                wrapAround: $viewModel.wrapAround
                            )
                        }
                        .clipped()
                        .overlay(alignment: .trailing) {
                            Image(systemName: "chevron.down")
                                .foregroundStyle(.secondary)
                                .font(.system(size: 5, weight: .black))
                                .padding(.leading, 4).padding(.trailing, -4)
                        }
                } else {
                    HStack(spacing: 0) {
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
                    }
                }
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
                            Color(
                                nsColor: viewModel.matchCase
                                  ? .controlAccentColor
                                  : .labelColor
                            )
                        )
                        .frame(width: 30, height: 20)
                })
                .toggleStyle(.icon)
            },
            helperText: helperText,
            clearable: true
        )
        .controlSize(.small)
        .fixedSize(horizontal: false, vertical: true)
        .focused($focus, equals: .find)
        .onSubmit {
            viewModel.moveToNextMatch()
        }
    }
}
