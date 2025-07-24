//
//  JumpToDefinitionLink.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 7/23/25.
//

import Foundation
import SwiftUI

public struct JumpToDefinitionLink: Identifiable, Sendable {
    public var id: String { url?.absoluteString ?? "\(targetRange)" }
    /// Leave as `nil` if the link is in the same document.
    public let url: URL?
    public let targetPosition: CursorPosition
    public let targetRange: NSRange

    public let typeName: String
    public let sourcePreview: String

    public let image: Image
    public let imageColor: Color

    public init(
        url: URL?,
        targetPosition: CursorPosition,
        targetRange: NSRange,
        typeName: String,
        sourcePreview: String,
        image: Image = Image(systemName: "dot.square.fill"),
        imageColor: Color = Color(NSColor.lightGray)
    ) {
        self.url = url
        self.targetPosition = targetPosition
        self.targetRange = targetRange
        self.typeName = typeName
        self.sourcePreview = sourcePreview
        self.image = image
        self.imageColor = imageColor
    }
}
