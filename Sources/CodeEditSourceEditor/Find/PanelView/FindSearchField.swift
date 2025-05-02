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

    var body: some View {
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
        .fixedSize(horizontal: false, vertical: true)
        .focused($focus, equals: .find)
        .onSubmit {
            viewModel.moveToNextMatch()
        }
    }
}
