//
//  JumpToDefinitionLinkList.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 7/23/25.
//

import SwiftUI

struct JumpToDefinitionLinkList: View {
    let items: [JumpToDefinitionLink]
    let font: NSFont
    let dismiss: () -> Void
    let onSelect: (JumpToDefinitionLink) -> Void

    private let maxVisibleItems = 5

    @State private var selectedRow: JumpToDefinitionLink?

    var body: some View {
        VStack {
            if items.count > maxVisibleItems {
                ScrollView {
                    listStack
                }
                .scrollIndicators(.hidden)
            } else {
                listStack
            }
            if let selectedRow {
                VStack {
                    Text(selectedRow.sourcePreview)
                        .font(Font(font))
                    HStack {
                        ForEach(selectedRow.url?.pathComponents ?? [], id: \.self) { component in
                            Text(component)
                            Image(systemName: "chevron.compact.right")
                        }
                    }
                    .font(.system(size: 12))
                }
            }
        }
    }

    @ViewBuilder private var listStack: some View {
        VStack(spacing: 0) {
            ForEach(items) { item in
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    item.image
                        .foregroundStyle(.white, item.imageColor)
                    Text(item.typeName)
                    Spacer(minLength: 0)
                }
                .font(Font(font))
                .contentShape(Rectangle())
                .onTapGesture {
                    if let selectedRow {
                        onSelect(selectedRow)
                    }
                    dismiss()
                }
                .onHover { isHovered in
                    if isHovered {
                        selectedRow = item
                    } else if !isHovered && selectedRow?.id == item.id {
                        selectedRow = nil
                    }
                }
            }
        }
    }
}

#if DEBUG

#Preview {
    JumpToDefinitionLinkList(items: [], font: .monospacedSystemFont(ofSize: 12, weight: .medium)) {

    } onSelect: { _ in

    }
}

#endif
