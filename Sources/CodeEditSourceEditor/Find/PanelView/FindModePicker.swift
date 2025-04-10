//
//  FindModePicker.swift
//  CodeEditSourceEditor
//
//  Created by Austin Condiff on 4/10/25.
//

import SwiftUI

struct FindModePicker: NSViewRepresentable {
    @Binding var mode: FindPanelMode
    @Binding var wrapAround: Bool
    @Environment(\.controlActiveState) var activeState
    let onToggleWrapAround: () -> Void

    func makeNSView(context: Context) -> NSView {
        let container = NSView()
        container.wantsLayer = true

        // Create the magnifying glass button
        let button = NSButton(frame: .zero)
        button.bezelStyle = .regularSquare
        button.isBordered = false
        button.controlSize = .small
        button.image = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: nil)?
            .withSymbolConfiguration(.init(pointSize: 12, weight: .regular))
        button.imagePosition = .imageOnly
        button.target = context.coordinator
        button.action = #selector(Coordinator.openMenu(_:))

        // Create the popup button
        let popup = NSPopUpButton(frame: .zero, pullsDown: false)
        popup.bezelStyle = .regularSquare
        popup.isBordered = false
        popup.controlSize = .small
        popup.font = .systemFont(ofSize: NSFont.systemFontSize(for: .small))
        popup.autoenablesItems = false

        // Calculate the required width
        let font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .small))
        let maxWidth = FindPanelMode.allCases.map { mode in
            mode.displayName.size(withAttributes: [.font: font]).width
        }.max() ?? 0
        let totalWidth = maxWidth + 28 // Add padding for the chevron and spacing

        // Create menu
        let menu = NSMenu()

        // Add mode items
        FindPanelMode.allCases.forEach { mode in
            let item = NSMenuItem(title: mode.displayName, action: #selector(Coordinator.modeSelected(_:)), keyEquivalent: "")
            item.target = context.coordinator
            item.tag = mode == .find ? 0 : 1
            menu.addItem(item)
        }

        // Add separator
        menu.addItem(.separator())

        // Add wrap around item
        let wrapItem = NSMenuItem(title: "Wrap Around", action: #selector(Coordinator.toggleWrapAround(_:)), keyEquivalent: "")
        wrapItem.target = context.coordinator
        wrapItem.state = wrapAround ? .on : .off
        menu.addItem(wrapItem)

        popup.menu = menu
        popup.selectItem(at: mode == .find ? 0 : 1)

        // Add subviews
        container.addSubview(button)
        container.addSubview(popup)

        // Set up constraints
        button.translatesAutoresizingMaskIntoConstraints = false
        popup.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
            button.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 16),
            button.heightAnchor.constraint(equalToConstant: 20),

            popup.leadingAnchor.constraint(equalTo: button.trailingAnchor),
            popup.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            popup.topAnchor.constraint(equalTo: container.topAnchor),
            popup.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            popup.widthAnchor.constraint(equalToConstant: totalWidth)
        ])

        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let popup = nsView.subviews.last as? NSPopUpButton {
            popup.selectItem(at: mode == .find ? 0 : 1)
            if let wrapItem = popup.menu?.items.last {
                wrapItem.state = wrapAround ? .on : .off
            }
        }

        if let button = nsView.subviews.first as? NSButton {
            button.contentTintColor = activeState == .inactive ? .tertiaryLabelColor : .secondaryLabelColor
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    var body: some View {
        let font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .small))
        let maxWidth = FindPanelMode.allCases.map { mode in
            mode.displayName.size(withAttributes: [.font: font]).width
        }.max() ?? 0
        let totalWidth = maxWidth + 28 // Add padding for the chevron and spacing

        return self.frame(width: totalWidth)
    }

    class Coordinator: NSObject {
        let parent: FindModePicker

        init(_ parent: FindModePicker) {
            self.parent = parent
        }

        @objc func openMenu(_ sender: NSButton) {
            if let popup = sender.superview?.subviews.last as? NSPopUpButton {
                popup.performClick(nil)
            }
        }

        @objc func modeSelected(_ sender: NSMenuItem) {
            parent.mode = sender.tag == 0 ? .find : .replace
        }

        @objc func toggleWrapAround(_ sender: NSMenuItem) {
            parent.onToggleWrapAround()
        }
    }
}
