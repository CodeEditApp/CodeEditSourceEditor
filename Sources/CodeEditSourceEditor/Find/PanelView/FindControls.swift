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

    var imageOpacity: CGFloat {
        viewModel.matchesEmpty ? 0.33 : 1
    }

    var dynamicPadding: CGFloat {
        condensed ? 0 : 5
    }

    var body: some View {
        HStack(spacing: 4) {
            ControlGroup {
                Button {
                    viewModel.moveToPreviousMatch()
                } label: {
                    Image(systemName: "chevron.left")
                        .opacity(imageOpacity)
                        .padding(.horizontal, dynamicPadding)
                }
                .help("Previous Match")
                .disabled(viewModel.matchesEmpty)

                Divider()
                    .overlay(Color(nsColor: .tertiaryLabelColor))
                Button {
                    viewModel.moveToNextMatch()
                } label: {
                    Image(systemName: "chevron.right")
                        .opacity(imageOpacity)
                        .padding(.horizontal, dynamicPadding)
                }
                .help("Next Match")
                .disabled(viewModel.matchesEmpty)
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
                .padding(.horizontal, dynamicPadding)
            }
            .buttonStyle(PanelButtonStyle())
        }
    }
}
