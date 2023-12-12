//
//  BracketPairHighlight.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 5/3/23.
//

import AppKit

/// An enum representing the type of highlight to use for bracket pairs.
public enum BracketPairHighlight: Equatable {
    /// Highlight both the opening and closing character in a pair with a bounding box.
    /// The boxes will stay on screen until the cursor moves away from the bracket pair.
    case bordered(color: NSColor)
    /// Flash a yellow highlight box on only the opposite character in the pair.
    /// This is closely matched to Xcode's flash highlight for bracket pairs, and animates in and out over the course
    /// of `0.75` seconds.
    case flash
    /// Highlight both the opening and closing character in a pair with an underline.
    /// The underline will stay on screen until the cursor moves away from the bracket pair.
    case underline(color: NSColor)

    public static func == (lhs: BracketPairHighlight, rhs: BracketPairHighlight) -> Bool {
        switch (lhs, rhs) {
        case (.flash, .flash):
            return true
        case (.bordered(let lhsColor), .bordered(let rhsColor)):
            return lhsColor == rhsColor
        case (.underline(let lhsColor), .underline(let rhsColor)):
            return lhsColor == rhsColor
        default:
            return false
        }
    }

    /// Returns `true` if the highlight should act on both the opening and closing bracket.
    var highlightsSourceBracket: Bool {
        switch self {
        case .bordered, .underline:
            return true
        case .flash:
            return false
        }
    }
}
