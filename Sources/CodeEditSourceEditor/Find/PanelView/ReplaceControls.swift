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

    var shouldDisableSingle: Bool {
        !viewModel.isFocused || viewModel.findText.isEmpty || viewModel.matchesEmpty
    }

    var shouldDisableAll: Bool {
        viewModel.findText.isEmpty || viewModel.matchesEmpty
    }

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
                    .opacity(shouldDisableSingle ? 0.33 : 1)
                }
                .help(condensed ? "Replace" : "")
                .disabled(shouldDisableSingle)
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
                    .opacity(shouldDisableAll ? 0.33 : 1)
                }
                .help(condensed ? "Replace All" : "")
                .disabled(shouldDisableAll)
                .frame(maxWidth: .infinity)
            }
            .controlGroupStyle(PanelControlGroupStyle())
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
