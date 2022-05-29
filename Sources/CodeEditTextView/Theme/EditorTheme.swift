//
//  EditorTheme.swift
//  CodeEditTextView
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
}
