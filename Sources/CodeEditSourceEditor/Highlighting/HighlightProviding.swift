//
//  HighlightProviding.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 1/18/23.
//

import Foundation
import CodeEditTextView
import CodeEditLanguages
import AppKit

/// The protocol a class must conform to to be used for highlighting.
public protocol HighlightProviding: AnyObject {
    /// Called once to set up the highlight provider with a data source and language.
    /// - Parameters:
    ///   - textView: The text view to use as a text source.
    ///   - codeLanguage: The language that should be used by the highlighter.
    func setUp(textView: TextView, codeLanguage: CodeLanguage)

    /// Notifies the highlighter that an edit is going to happen in the given range.
    /// - Parameters:
    ///   - textView: The text view to use.
    ///   - range: The range of the incoming edit.
    func willApplyEdit(textView: TextView, range: NSRange)

    /// Notifies the highlighter of an edit and in exchange gets a set of indices that need to be re-highlighted.
    /// The returned `IndexSet` should include all indexes that need to be highlighted, including any inserted text.
    /// - Parameters:
    ///   - textView: The text view to use.
    ///   - range: The range of the edit.
    ///   - delta: The length of the edit, can be negative for deletions.
    /// - Returns: an `IndexSet` containing all Indices to invalidate.
    func applyEdit(textView: TextView, range: NSRange, delta: Int, completion: @escaping (IndexSet) -> Void)

    /// Queries the highlight provider for any ranges to apply highlights to. The highlight provider should return an
    /// array containing all ranges to highlight, and the capture type for the range. Any ranges or indexes
    /// excluded from the returned array will be treated as plain text and highlighted as such.
    /// - Parameters:
    ///   - textView: The text view to use.
    ///   - range: The range to query.
    /// - Returns: All highlight ranges for the queried ranges.
    func queryHighlightsFor(textView: TextView, range: NSRange, completion: @escaping ([HighlightRange]) -> Void)
}

extension HighlightProviding {
    public func willApplyEdit(textView: TextView, range: NSRange) { }
}
