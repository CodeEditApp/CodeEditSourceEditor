//
//  ReplaceControls.swift
//  CodeEditSourceEditor
//
//  Created by Austin Condiff on 4/30/25.
//

import SwiftUI

struct ReplaceControls: View {
    @ObservedObject var viewModel: FindPanelViewModel
    var condensed: Bool

    var body: some View {
        HStack(spacing: 4) {
            ControlGroup {
                Button {
                    viewModel.replace()
                } label: {
                    Group {
                        if condensed {
                            Image(systemName: "arrow.turn.up.right")
                        } else {
                            Text("Replace")
                        }
                    }
                    .opacity(
                        !viewModel.isFocused
                        || viewModel.findText.isEmpty
                        || viewModel.matchCount == 0 ? 0.33 : 1
                    )
                }
                .help(condensed ? "Replace" : "")
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
                    Group {
                        if condensed {
                            Image(systemName: "text.insert")
                        } else {
                            Text("All")
                        }
                    }
                    .opacity(viewModel.findText.isEmpty || viewModel.matchCount == 0 ? 0.33 : 1)
                }
                .help(condensed ? "Replace All" : "")
                .disabled(viewModel.findText.isEmpty || viewModel.matchCount == 0)
                .frame(maxWidth: .infinity)
            }
            .controlGroupStyle(PanelControlGroupStyle())
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
