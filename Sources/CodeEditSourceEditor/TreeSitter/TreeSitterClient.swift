//
//  TreeSitterClient.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 9/12/22.
//

import Foundation
import CodeEditTextView
import CodeEditLanguages
import SwiftTreeSitter
import OSLog

/// # TreeSitterClient
///
/// ``TreeSitterClient`` is an actor type that manages a tree-sitter syntax tree and provides an API for notifying that
/// tree of edits and querying the tree.
///
/// This type also conforms to ``HighlightProviding`` to provide syntax highlighting.
///
public actor TreeSitterClient: HighlightProviding {
    static let logger: Logger = Logger(subsystem: "com.CodeEdit.CodeEditSourceEditor", category: "TreeSitterClient")

    // MARK: - Properties

    /// A callback to use to efficiently fetch portions of text.
    var readBlock: Parser.ReadBlock?

    /// A callback used to fetch text for queries.
    var readCallback: SwiftTreeSitter.Predicate.TextProvider?

    /// The internal tree-sitter layer tree object.
    var state: TreeSitterState?

    /// The end point of the previous edit.
    private var oldEndPoint: Point?

    // MARK: - Constants

    enum Constants {
        /// The maximum amount of limits a cursor can match during a query.
        /// Used to ensure performance in large files, even though we generally limit the query to the visible range.
        /// Neovim encountered this issue and uses 64 for their limit. Helix uses 256 due to issues with some
        /// languages when using 64.
        /// See: https://github.com/neovim/neovim/issues/14897
        /// And: https://github.com/helix-editor/helix/pull/4830
        static let treeSitterMatchLimit = 256

        /// The timeout for parsers to re-check if a task is canceled. This constant represents the period between
        /// checks.
        static let parserTimeout: TimeInterval = 0.1
    }

    // MARK: - HighlightProviding

    /// Set up the client with a text view and language.
    /// - Parameters:
    ///   - textView: The text view to use as a data source.
    ///               A weak reference will be kept for the lifetime of this object.
    ///   - codeLanguage: The language to use for parsing.
    public func setUp(textView: TextView, codeLanguage: CodeLanguage) async {
        self.readBlock = await textView.createReadBlock()
        self.readCallback = await textView.createReadCallback()

        let task = Task.detached {
            await self.setState(
                language: codeLanguage,
                readCallback: self.readCallback!,
                readBlock: self.readBlock!
            )
        }
        await task.value
    }

    private func setState(
        language: CodeLanguage,
        readCallback: @escaping SwiftTreeSitter.Predicate.TextProvider,
        readBlock: @escaping Parser.ReadBlock
    ) async {
        self.state?.setLanguage(language)
        self.state?.parseDocument(readCallback: readCallback, readBlock: readBlock)
    }

    /// Notifies the highlighter of an edit and in exchange gets a set of indices that need to be re-highlighted.
    /// The returned `IndexSet` should include all indexes that need to be highlighted, including any inserted text.
    /// - Parameters:
    ///   - textView: The text view to use.
    ///   - range: The range of the edit.
    ///   - delta: The length of the edit, can be negative for deletions.
    ///   - completion: The function to call with an `IndexSet` containing all Indices to invalidate.
    public func applyEdit(textView: TextView, range: NSRange, delta: Int) async -> IndexSet {
        let oldEndPoint: Point
        if self.oldEndPoint != nil {
            oldEndPoint = self.oldEndPoint!
        } else {
            oldEndPoint = await textView.pointForLocation(range.max) ?? .zero
        }
        guard let edit = InputEdit(
            range: range,
            delta: delta,
            oldEndPoint: oldEndPoint,
            textView: textView
        ) else {
            return IndexSet()
        }
        return applyEdit(edit: edit)
    }

    public func willApplyEdit(textView: TextView, range: NSRange) async {
        oldEndPoint = await textView.pointForLocation(range.max)
    }

    /// Initiates a highlight query.
    /// - Parameters:
    ///   - textView: The text view to use.
    ///   - range: The range to limit the highlights to.
    ///   - completion: Called when the query completes.
    public func queryHighlightsFor(textView: TextView, range: NSRange) async -> [HighlightRange] {
        return queryHighlightsForRange(range: range)
    }
}
