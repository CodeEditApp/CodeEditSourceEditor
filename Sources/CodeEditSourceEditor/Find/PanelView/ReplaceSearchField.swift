//
//  ReplaceSearchField.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 4/18/25.
//

import SwiftUI

struct ReplaceSearchField: View {
    @ObservedObject var viewModel: FindPanelViewModel
    @FocusState.Binding var focus: FindPanelView.FindPanelFocus?
    @Binding var findModePickerWidth: CGFloat
    var condensed: Bool

    var body: some View {
        PanelTextField(
            "Text",
            text: $viewModel.replaceText,
            leadingAccessories: {
                if condensed {
                    Image(systemName: "pencil")
                        .foregroundStyle(.secondary)
                        .padding(.leading, 8)
                } else {
                    HStack(spacing: 0) {
                        HStack(spacing: 0) {
                            Image(systemName: "pencil")
                                .foregroundStyle(.secondary)
                                .padding(.leading, 8)
                                .padding(.trailing, 5)
                            Text("With")
                        }
                        .frame(width: findModePickerWidth, alignment: .leading)
                        Divider()
                    }
                }
            },
            clearable: true
        )
        .controlSize(.small)
        .fixedSize(horizontal: false, vertical: true)
        .focused($focus, equals: .replace)
    }
}
