//
//  SourceEditorState.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 6/19/25.
//

import AppKit

public struct SourceEditorState: Equatable, Hashable, Sendable, Codable {
    public var cursorPositions: [CursorPosition] = []
    public var scrollPosition: CGPoint?
    public var findText: String?
    public var findPanelVisible: Bool = false

    public init(
        cursorPositions: [CursorPosition],
        scrollPosition: CGPoint? = nil,
        findText: String? = nil,
        findPanelVisible: Bool = false
    ) {
        self.cursorPositions = cursorPositions
        self.scrollPosition = scrollPosition
        self.findText = findText
        self.findPanelVisible = findPanelVisible
    }
}
