//
//  HighlightProviding.swift
//  
//
//  Created by Khan Winter on 1/18/23.
//

import Foundation
import CodeEditLanguages
import STTextView
import AppKit

/// The protocol a class must conform to to be used for highlighting.
public protocol HighlightProviding {
    /// A unique identifier for the highlighter object.
    /// Example: `"CodeEdit.TreeSitterHighlighter"`
    /// - Note: This does not need to be *globally* unique, merely unique across all the highlighters used.
    var identifier: String { get }

    /// Updates the highlighter's code language.
    /// - Parameters:
    ///   - codeLanguage: The langugage that should be used by the highlighter.
    func setLanguage(codeLanguage: CodeLanguage)

    /// Notifies the highlighter of an edit and in exchange gets a set of indices that need to be re-highlighted.
    /// The returned `IndexSet` should include all indexes that need to be highlighted, including any inserted text.
    /// - Parameters:
    ///   - textView:The text view to use.
    ///   - range: The range of the edit.
    ///   - delta: The length of the edit, can be negative for deletions.
    ///   - completion: The function to call with an `IndexSet` containing all Indices to invalidate.
    func applyEdit(textView: HighlighterTextView,
                   range: NSRange,
                   delta: Int,
                   completion: @escaping ((IndexSet) -> Void))

    /// Queries the highlight provider for any ranges to apply highlights to. The highlight provider should return an
    /// array containing all ranges to highlight, and the capture type for the range. Any ranges or indexes
    /// excluded from the returned array will be treated as plain text and highlighted as such.
    /// - Parameters:
    ///   - textView: The text view to use.
    ///   - range: The range to operate on.
    ///   - completion: Function to call with all ranges to highlight
    func queryColorsFor(textView: HighlighterTextView,
                        range: NSRange,
                        completion: @escaping (([HighlightRange]) -> Void))
}
