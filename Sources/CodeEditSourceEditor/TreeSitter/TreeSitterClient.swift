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
/// can throw an ``TreeSitterClient/Error/syncUnavailable`` error if an asynchronous or synchronous call is already
/// being made on the object. In those cases it is up to the caller to decide whether or not to retry asynchronously.
///
/// The only exception to the above rule is the ``HighlightProviding`` conformance methods. The methods for that
/// implementation may return synchronously or asynchronously depending on a variety of factors such as document
/// length, edit length, highlight length and if the object is available for a synchronous call.
public final class TreeSitterClient: HighlightProviding {
    static let logger: Logger = Logger(subsystem: "com.CodeEdit.CodeEditSourceEditor", category: "TreeSitterClient")

    /// The number of operations running or enqueued to run on the dispatch queue. This variable **must** only be
    /// changed from the main thread or race conditions are very likely.
    private var runningOperationCount = 0

    /// The number of times the object has been set up. Used to cancel async tasks if
    /// ``TreeSitterClient/setUp(textView:codeLanguage:)`` is called.
    private var setUpCount = 0

    /// The concurrent queue to perform operations on.
    private let operationQueue = DispatchQueue(
        label: "CodeEditSourceEditor.TreeSitter.EditQueue",
        qos: .userInteractive
    )

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

        /// The maximum length of an edit before it must be processed asynchronously
        static let maxSyncEditLength: Int = 1024

        /// The maximum length a document can be before all queries and edits must be processed asynchronously.
        static let maxSyncContentLength: Int = 1_000_000

        /// The maximum length a query can be before it must be performed asynchronously.
        static let maxSyncQueryLength: Int = 4096
    }

    public enum Error: Swift.Error {
        case syncUnavailable
    }

    // MARK: - HighlightProviding

    /// Set up the client with a text view and language.
    /// - Parameters:
    ///   - textView: The text view to use as a data source.
    ///               A weak reference will be kept for the lifetime of this object.
    ///   - codeLanguage: The language to use for parsing.
    public func setUp(textView: TextView, codeLanguage: CodeLanguage) {
        Self.logger.debug("TreeSitterClient setting up with language: \(codeLanguage.id.rawValue, privacy: .public)")

        self.readBlock = textView.createReadBlock()
        self.readCallback = textView.createReadCallback()

        self.setState(
            language: codeLanguage,
            readCallback: self.readCallback!,
            readBlock: self.readBlock!
        )
    }

    /// Sets the client's new state.
    /// - Parameters:
    ///   - language: The language to use.
    ///   - readCallback: The callback to use to read text from the document.
    ///   - readBlock: The callback to use to read blocks of text from the document.
    private func setState(
        language: CodeLanguage,
        readCallback: @escaping SwiftTreeSitter.Predicate.TextProvider,
        readBlock: @escaping Parser.ReadBlock
    ) {
        setUpCount += 1
        performAsync { [weak self] in
            self?.state = TreeSitterState(codeLanguage: language, readCallback: readCallback, readBlock: readBlock)
        }
    }

    // MARK: - Async Operations

    /// Performs the given operation asynchronously.
    ///
    /// All completion handlers passed to this function will be enqueued on the `operationQueue` dispatch queue,
    /// ensuring serial access to this class.
    ///
    /// This function will handle ensuring balanced increment/decrements are made to the `runningOperationCount` in
    /// a safe manner.
    ///
    /// - Note: While in debug mode, this method will throw an assertion failure if not called from the Main thread.
    /// - Parameter operation: The operation to perform
    private func performAsync(_ operation: @escaping () -> Void) {
        assertMain()
        runningOperationCount += 1
        let setUpCountCopy = setUpCount
        operationQueue.async { [weak self] in
            guard self != nil && self?.setUpCount == setUpCountCopy else { return }
            operation()
            DispatchQueue.main.async {
                self?.runningOperationCount -= 1
            }
        }
    }

    /// Attempts to perform a synchronous operation on the client.
    ///
    /// The operation will be dispatched synchronously to the `operationQueue`, this function will return once the
    /// operation is finished.
    ///
    /// - Note: While in debug mode, this method will throw an assertion failure if not called from the Main thread.
    /// - Parameter operation: The operation to perform synchronously.
    /// - Throws: Can throw an ``TreeSitterClient/Error/syncUnavailable`` error if it's determined that an async
    ///           operation is unsafe.
    private func performSync(_ operation: @escaping () -> Void) throws {
        assertMain()

        guard runningOperationCount == 0 else {
            throw Error.syncUnavailable
        }

        runningOperationCount += 1

        operationQueue.sync {
            operation()
        }

        self.runningOperationCount -= 1
    }

    /// Assert that the caller is calling from the main thread.
    private func assertMain() {
#if DEBUG
        if !Thread.isMainThread {
            assertionFailure("TreeSitterClient used from non-main queue. This will cause race conditions.")
        }
#endif
    }

    // MARK: - HighlightProviding

    /// Notifies the highlighter of an edit and in exchange gets a set of indices that need to be re-highlighted.
    /// The returned `IndexSet` should include all indexes that need to be highlighted, including any inserted text.
    /// - Parameters:
    ///   - textView: The text view to use.
    ///   - range: The range of the edit.
    ///   - delta: The length of the edit, can be negative for deletions.
    ///   - completion: The function to call with an `IndexSet` containing all Indices to invalidate.
    public func applyEdit(textView: TextView, range: NSRange, delta: Int, completion: @escaping (IndexSet) -> Void) {
        let oldEndPoint: Point

        if self.oldEndPoint != nil {
            oldEndPoint = self.oldEndPoint!
        } else {
            oldEndPoint = textView.pointForLocation(range.max) ?? .zero
        }

        guard let edit = InputEdit(
            range: range,
            delta: delta,
            oldEndPoint: oldEndPoint,
            textView: textView
        ) else {
            completion(IndexSet())
            return
        }

        let operation = { [weak self] in
            let invalidatedRanges = self?.applyEdit(edit: edit) ?? IndexSet()
            completion(invalidatedRanges)
        }

        do {
            let longEdit = range.length > Constants.maxSyncEditLength
            let longDocument = textView.documentRange.length > Constants.maxSyncContentLength

            if longEdit || longDocument {

            }
            try performSync(operation)
        } catch {
            performAsync(operation)
        }
    }

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
        completion: @escaping ([HighlightRange]) -> Void
    ) {
        let operation = { [weak self] in
            let highlights = self?.queryHighlightsForRange(range: range)
            DispatchQueue.main.async {
                completion(highlights ?? [])
            }
        }

        do {
            let longQuery = range.length > Constants.maxSyncQueryLength
            let longDocument = textView.documentRange.length > Constants.maxSyncContentLength

            if longQuery || longDocument {
                throw Error.syncUnavailable
            }
            try performSync(operation)
        } catch {
            performAsync(operation)
        }
    }
}
