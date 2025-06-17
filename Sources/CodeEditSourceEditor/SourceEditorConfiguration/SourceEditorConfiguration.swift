//
//  SourceEditorConfiguration.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 6/16/25.
//

import AppKit

public struct SourceEditorConfiguration: Equatable {
    public var appearance: Appearance
    public var behavior: Behavior
    public var peripherals: Peripherals
    public var layout: Layout

    public init(
        appearance: Appearance,
        behavior: Behavior = .init(),
        layout: Layout = .init(),
        peripherals: Peripherals = .init()
    ) {
        self.appearance = appearance
        self.behavior = behavior
        self.layout = layout
        self.peripherals = peripherals
    }

    @MainActor
    func didSetOnController(controller: TextViewController, oldConfig: SourceEditorConfiguration?) {
        appearance.didSetOnController(controller: controller, oldConfig: oldConfig?.appearance)
        behavior.didSetOnController(controller: controller, oldConfig: oldConfig?.behavior)
        layout.didSetOnController(controller: controller, oldConfig: oldConfig?.layout)
        peripherals.didSetOnController(controller: controller, oldConfig: oldConfig?.peripherals)
    }
}
