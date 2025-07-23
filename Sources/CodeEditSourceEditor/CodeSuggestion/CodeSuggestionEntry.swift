//
//  CodeSuggestionEntry.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 7/22/25.
//

import AppKit

/// Represents an item that can be displayed in the code suggestion view
public protocol CodeSuggestionEntry {
    var view: NSView { get }
}
