//
//  TextView+Menu.swift
//  
//
//  Created by Khan Winter on 8/21/23.
//

import AppKit

extension TextView {
    open override class var defaultMenu: NSMenu? {
        let menu = NSMenu()

        menu.items = [
            NSMenuItem(title: "Copy", action: #selector(undo(_:)), keyEquivalent: "c"),
            NSMenuItem(title: "Paste", action: #selector(undo(_:)), keyEquivalent: "v")
        ]

        return menu
    }
}
