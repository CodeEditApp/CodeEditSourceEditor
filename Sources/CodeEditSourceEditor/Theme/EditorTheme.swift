//
//  EditorTheme.swift
//  CodeEditSourceEditor
//
//  Created by Lukas Pistrol on 29.05.22.
//

import SwiftUI

/// A collection of `NSColor` used for syntax higlighting
public struct EditorTheme {

    public var text: NSColor
    public var insertionPoint: NSColor
    public var invisibles: NSColor
    public var background: NSColor
    public var lineHighlight: NSColor
    public var selection: NSColor
    public var keywords: NSColor
    public var commands: NSColor
    public var types: NSColor
    public var attributes: NSColor
    public var variables: NSColor
    public var values: NSColor
    public var numbers: NSColor
    public var strings: NSColor
    public var characters: NSColor
    public var comments: NSColor

    public init(
        text: NSColor,
        insertionPoint: NSColor,
        invisibles: NSColor,
        background: NSColor,
        lineHighlight: NSColor,
        selection: NSColor,
        keywords: NSColor,
        commands: NSColor,
        types: NSColor,
        attributes: NSColor,
        variables: NSColor,
        values: NSColor,
        numbers: NSColor,
        strings: NSColor,
        characters: NSColor,
        comments: NSColor
    ) {
        self.text = text
        self.insertionPoint = insertionPoint
        self.invisibles = invisibles
        self.background = background
        self.lineHighlight = lineHighlight
        self.selection = selection
        self.keywords = keywords
        self.commands = commands
        self.types = types
        self.attributes = attributes
        self.variables = variables
        self.values = values
        self.numbers = numbers
        self.strings = strings
        self.characters = characters
        self.comments = comments
    }

    /// Get the color from ``theme`` for the specified capture name.
    /// - Parameter capture: The capture name
    /// - Returns: A `NSColor`
    func colorFor(_ capture: CaptureName?) -> NSColor {
        switch capture {
        case .include, .constructor, .keyword, .boolean, .variableBuiltin,
                .keywordReturn, .keywordFunction, .repeat, .conditional, .tag:
            return keywords
        case .comment: return comments
        case .variable, .property: return variables
        case .function, .method: return variables
        case .number, .float: return numbers
        case .string: return strings
        case .type: return types
        case .parameter: return variables
        case .typeAlternate: return attributes
        default: return text
        }
    }
}

extension EditorTheme: Equatable {
    public static func == (lhs: EditorTheme, rhs: EditorTheme) -> Bool {
        return lhs.text == rhs.text &&
        lhs.insertionPoint == rhs.insertionPoint &&
        lhs.invisibles == rhs.invisibles &&
        lhs.background == rhs.background &&
        lhs.lineHighlight == rhs.lineHighlight &&
        lhs.selection == rhs.selection &&
        lhs.keywords == rhs.keywords &&
        lhs.commands == rhs.commands &&
        lhs.types == rhs.types &&
        lhs.attributes == rhs.attributes &&
        lhs.variables == rhs.variables &&
        lhs.values == rhs.values &&
        lhs.numbers == rhs.numbers &&
        lhs.strings == rhs.strings &&
        lhs.characters == rhs.characters &&
        lhs.comments == rhs.comments
    }
}
