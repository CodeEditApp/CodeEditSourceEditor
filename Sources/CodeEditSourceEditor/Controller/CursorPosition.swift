//
//  CursorPosition.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 11/13/23.
//

import Foundation

/// # Cursor Position
///
/// Represents the position of a cursor in a document.
/// Provides information about the range of the selection relative to the document, and the line-column information.
/// 
/// Can be initialized by users without knowledge of either column and line position or range in the document.
/// When initialized by users, certain values may be set to `NSNotFound` or `-1` until they can be filled in by the text
/// controller.
/// 
public struct CursorPosition: Sendable, Codable, Equatable {
    /// Initialize a cursor position.
    ///
    /// When this initializer is used, ``CursorPosition/range`` will be initialized to `NSNotFound`.
    /// The range value, however, be filled when updated by ``CodeEditSourceEditor`` via a `Binding`, or when it appears
    /// in the``TextViewController/cursorPositions`` array.
    ///
    /// - Parameters:
    ///   - line: The line of the cursor position, 1-indexed.
    ///   - column: The column of the cursor position, 1-indexed.
    public init(line: Int, column: Int) {
        self.range = .notFound
        self.line = line
        self.column = column
    }

    /// Initialize a cursor position.
    ///
    /// When this initializer is used, both ``CursorPosition/line`` and ``CursorPosition/column`` will be initialized
    /// to `-1`. They will, however, be filled when updated by ``CodeEditSourceEditor`` via a `Binding`, or when it
    /// appears in the ``TextViewController/cursorPositions`` array.
    ///
    /// - Parameter range: The range of the cursor position.
    public init(range: NSRange) {
        self.range = range
        self.line = -1
        self.column = -1
    }

    /// Private initializer.
    /// - Parameters:
    ///   - range: The range of the position.
    ///   - line: The line of the position.
    ///   - column: The column of the position.
    init(range: NSRange, line: Int, column: Int) {
        self.range = range
        self.line = line
        self.column = column
    }

    /// The range of the selection.
    public let range: NSRange
    /// The line the cursor is located at. 1-indexed.
    /// If ``CursorPosition/range`` is not empty, this is the line at the beginning of the selection.
    public let line: Int
    /// The column the cursor is located at. 1-indexed.
    /// If ``CursorPosition/range`` is not empty, this is the column at the beginning of the selection.
    public let column: Int
}
