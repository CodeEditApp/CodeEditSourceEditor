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
/// ``TreeSitterClient`` is an class that manages a tree-sitter syntax tree and provides an API for notifying that
/// tree of edits and querying the tree. This type also conforms to ``HighlightProviding`` to provide syntax
/// highlighting.
///
/// The APIs this object provides can perform either asynchronously or synchronously. All calls to this object must
/// first be dispatched from the main queue to ensure serial access to internal properties. Any synchronous methods
/// can throw an ``TreeSitterClientExecutor/Error/syncUnavailable`` error if an asynchronous or synchronous call is
/// already being made on the object. In those cases it is up to the caller to decide whether or not to retry
/// asynchronously.
/// 
/// The only exception to the above rule is the ``HighlightProviding`` conformance methods. The methods for that
/// implementation may return synchronously or asynchronously depending on a variety of factors such as document
/// length, edit length, highlight length and if the object is available for a synchronous call.
public final class TreeSitterClient: HighlightProviding {
    static let logger: Logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "", category: "TreeSitterClient")

    enum TreeSitterClientError: Error {
        case invalidEdit
    }

    // MARK: - Properties

    /// A callback to use to efficiently fetch portions of text.
    var readBlock: Parser.ReadBlock?

    /// A callback used to fetch text for queries.
    var readCallback: SwiftTreeSitter.Predicate.TextProvider?

    /// The internal tree-sitter layer tree object.
    var state: TreeSitterState?

    package var executor: TreeSitterExecutor = .init()

    /// The end point of the previous edit.
    private var oldEndPoint: Point?

    @Atomic package var pendingEdits: [InputEdit] = []

    /// Optional flag to force every operation to be done on the caller's thread.
    var forceSyncOperation: Bool = false

    // MARK: - Constants

    public enum Constants {
        /// The maximum amount of limits a cursor can match during a query.
        ///
        /// Used to ensure performance in large files, even though we generally limit the query to the visible range.
        /// Neovim encountered this issue and uses 64 for their limit. Helix uses 256 due to issues with some
        /// languages when using 64.
        /// See: [github.com/neovim](https://github.com/neovim/neovim/issues/14897)
        /// And: [github.com/helix-editor](https://github.com/helix-editor/helix/pull/4830)
        public static var matchLimit = 256

        /// The timeout for parsers to re-check if a task is canceled. This constant represents the period between
        /// checks and is directly related to editor responsiveness.
        public static var parserTimeout: TimeInterval = 0.05

        /// The maximum length of an edit before it must be processed asynchronously
        public static var maxSyncEditLength: Int = 1024

        /// The maximum length a document can be before all queries and edits must be processed asynchronously.
        public static var maxSyncContentLength: Int = 1_000_000

        /// The maximum length a query can be before it must be performed asynchronously.
        public static var maxSyncQueryLength: Int = 4096

        /// The number of characters to read in a read block.
        ///
        /// This has diminishing returns on the number of times the read block is called as this number gets large.
        public static var charsToReadInBlock: Int = 4096

        /// The duration before a long parse notification is sent.
        public static var longParseTimeout: Duration = .seconds(0.5)

        /// The notification name sent when a long parse is detected.
        public static var longParse: Notification.Name = .init("CodeEditSourceEditor.longParseNotification")

        /// The notification name sent when a long parse is finished.
        public static var longParseFinished: Notification.Name = .init(
            "CodeEditSourceEditor.longParseFinishedNotification"
        )
    }

    // MARK: - HighlightProviding

    /// Set up the client with a text view and language.
    /// - Parameters:
    ///   - textView: The text view to use as a data source.
    ///               A weak reference will be kept for the lifetime of this object.
    ///   - codeLanguage: The language to use for parsing.
    public func setUp(textView: TextView, codeLanguage: CodeLanguage) {
        Self.logger.debug("TreeSitterClient setting up with language: \(codeLanguage.id.rawValue, privacy: .public)")

        let readBlock = textView.createReadBlock()
        let readCallback = textView.createReadCallback()
        self.readBlock = readBlock
        self.readCallback = readCallback

        let operation = { [weak self] in
            let state = TreeSitterState(
                codeLanguage: codeLanguage,
                readCallback: readCallback,
                readBlock: readBlock
            )
            self?.state = state
        }

        executor.cancelAll(below: .all)
        if forceSyncOperation {
            executor.execSync(operation)
        } else {
            executor.execAsync(priority: .reset, operation: operation, onCancel: {})
        }
    }

    // MARK: - HighlightProviding

    /// Notifies the highlighter of an edit and in exchange gets a set of indices that need to be re-highlighted.
    /// The returned `IndexSet` should include all indexes that need to be highlighted, including any inserted text.
    /// - Parameters:
    ///   - textView: The text view to use.
    ///   - range: The range of the edit.
    ///   - delta: The length of the edit, can be negative for deletions.
    ///   - completion: The function to call with an `IndexSet` containing all Indices to invalidate.
    public func applyEdit(
        textView: TextView,
        range: NSRange,
        delta: Int,
        completion: @escaping @MainActor (Result<IndexSet, Error>) -> Void
    ) {
        let oldEndPoint: Point = self.oldEndPoint ?? textView.pointForLocation(range.max) ?? .zero
        guard let edit = InputEdit(range: range, delta: delta, oldEndPoint: oldEndPoint, textView: textView) else {
            completion(.failure(TreeSitterClientError.invalidEdit))
            return
        }

        let operation = { [weak self] in
            let invalidatedRanges = self?.applyEdit(edit: edit) ?? IndexSet()
            DispatchQueue.dispatchMainIfNot { completion(.success(invalidatedRanges)) }
        }

        let longEdit = range.length > Constants.maxSyncEditLength
        let longDocument = textView.documentRange.length > Constants.maxSyncContentLength

        if forceSyncOperation {
            executor.execSync(operation)
            return
        }

        if longEdit || longDocument || !executor.execSync(operation).isSuccess {
            executor.cancelAll(below: .reset) // Cancel all edits, add it to the pending edit queue
            executor.execAsync(
                priority: .edit,
                operation: operation,
                onCancel: { [weak self] in
                    self?.pendingEdits.append(edit)
                    DispatchQueue.dispatchMainIfNot {
                        completion(.failure(HighlightProvidingError.operationCancelled))
                    }
                }
            )
        }
    }

    /// Called before an edit is sent. We use this to set the ``oldEndPoint`` variable so tree-sitter knows where
    /// the document used to end.
    /// - Parameters:
    ///   - textView: The text view used.
    ///   - range: The range that will be edited.
    public func willApplyEdit(textView: TextView, range: NSRange) {
        oldEndPoint = textView.pointForLocation(range.max)
    }

    /// Initiates a highlight query.
    /// - Parameters:
    ///   - textView: The text view to use.
    ///   - range: The range to limit the highlights to.
    ///   - completion: Called when the query completes.
    public func queryHighlightsFor(
        textView: TextView,
        range: NSRange,
        completion: @escaping @MainActor (Result<[HighlightRange], Error>) -> Void
    ) {
        let operation = { [weak self] in
            let highlights = self?.queryHighlightsForRange(range: range)
            DispatchQueue.dispatchMainIfNot { completion(.success(highlights ?? [])) }
        }

        let longQuery = range.length > Constants.maxSyncQueryLength
        let longDocument = textView.documentRange.length > Constants.maxSyncContentLength

        if forceSyncOperation {
            executor.execSync(operation)
            return
        }

        if longQuery || longDocument || !executor.execSync(operation).isSuccess {
            executor.execAsync(
                priority: .access,
                operation: operation,
                onCancel: {
                    DispatchQueue.dispatchMainIfNot {
                        completion(.failure(HighlightProvidingError.operationCancelled))
                    }
                }
            )
        }
    }
}
