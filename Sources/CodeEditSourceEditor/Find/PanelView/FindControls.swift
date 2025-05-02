//
//  FindControls.swift
//  CodeEditSourceEditor
//
//  Created by Austin Condiff on 4/30/25.
//

import SwiftUI

struct FindControls: View {
    @ObservedObject var viewModel: FindPanelViewModel
    var condensed: Bool

    var body: some View {
        HStack(spacing: 4) {
            ControlGroup {
                Button {
                    viewModel.moveToPreviousMatch()
                } label: {
                    Image(systemName: "chevron.left")
                        .opacity(viewModel.matchCount == 0 ? 0.33 : 1)
                        .padding(.horizontal, condensed ? 0 : 5)
                }
                .help("Previous Match")
                .disabled(viewModel.matchCount == 0)
                Divider()
                    .overlay(Color(nsColor: .tertiaryLabelColor))
                Button {
                    viewModel.moveToNextMatch()
                } label: {
                    Image(systemName: "chevron.right")
                        .opacity(viewModel.matchCount == 0 ? 0.33 : 1)
                        .padding(.horizontal, condensed ? 0 : 5)
                }
                .help("Next Match")
                .disabled(viewModel.matchCount == 0)
            }
            .controlGroupStyle(PanelControlGroupStyle())
            .fixedSize()
            Button {
                viewModel.dismiss?()
            } label: {
                Group {
                    if condensed {
                        Image(systemName: "xmark")
                    } else {
                        Text("Done")
                    }
                }
                .help(condensed ? "Done" : "")
                .padding(.horizontal, condensed ? 0 : 5)
            }
            .buttonStyle(PanelButtonStyle())
        }
    }
}
