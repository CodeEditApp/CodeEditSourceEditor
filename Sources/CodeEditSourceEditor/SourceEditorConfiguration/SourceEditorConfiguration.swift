//
//  SourceEditorConfiguration.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 6/16/25.
//

import AppKit

/// Configuration object for the ``SourceEditor``. Determines appearance, behavior, layout and what features are
/// enabled (peripherals).
///
/// To update the configuration, update the ``TextViewController/configuration`` property, or pass a value to the
/// ``SourceEditor`` SwiftUI API. Both methods will call the `didSetOnController` method on this type, which will
/// update the text controller as necessary for the new configuration.
public struct SourceEditorConfiguration: Equatable {
    /// Configure the appearance of the editor. Font, theme, line height, etc.
    public var appearance: Appearance
    /// Configure the behavior of the editor. Indentation, edit-ability, select-ability, etc.
    public var behavior: Behavior
    /// Configure the layout of the editor. Content insets, etc.
    public var layout: Layout
    /// Configure enabled features on the editor. Gutter (line numbers), minimap, etc.
    public var peripherals: Peripherals

    /// Create a new configuration object.
    /// - Parameters:
    ///   - appearance: Configure the appearance of the editor. Font, theme, line height, etc.
    ///   - behavior: Configure the behavior of the editor. Indentation, edit-ability, select-ability, etc.
    ///   - layout: Configure the layout of the editor. Content insets, etc.
    ///   - peripherals: Configure enabled features on the editor. Gutter (line numbers), minimap, etc.
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

    /// Update the controller for a new configuration object.
    ///
    /// This object is the new one, the old one is passed in as an optional, assume that it's the first setup
    /// when `oldConfig` is `nil`.
    ///
    /// This method should try to update a minimal number of properties as possible by checking for changes
    /// before updating.
    @MainActor
    func didSetOnController(controller: TextViewController, oldConfig: SourceEditorConfiguration?) {
        appearance.didSetOnController(controller: controller, oldConfig: oldConfig?.appearance)
        behavior.didSetOnController(controller: controller, oldConfig: oldConfig?.behavior)
        layout.didSetOnController(controller: controller, oldConfig: oldConfig?.layout)
        peripherals.didSetOnController(controller: controller, oldConfig: oldConfig?.peripherals)
    }
}
