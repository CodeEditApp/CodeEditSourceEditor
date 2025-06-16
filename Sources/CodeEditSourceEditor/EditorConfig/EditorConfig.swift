//
//  EditorConfig.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 6/16/25.
//

import AppKit

public struct EditorConfig: Equatable {
    public var appearance: Appearance
    public var behavior: Behavior
    public var peripherals: Peripherals
    public var layout: Layout

    public init(
        appearance: Appearance,
        behavior: Behavior,
        peripherals: Peripherals = .init(),
        layout: Layout = .init()
    ) {
        self.appearance = appearance
        self.behavior = behavior
        self.peripherals = peripherals
        self.layout = layout
    }
}
