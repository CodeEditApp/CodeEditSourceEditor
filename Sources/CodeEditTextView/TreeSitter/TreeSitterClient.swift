//
//  TreeSitterClient.swift
//  
//
//  Created by Khan Winter on 9/12/22.
//

import Foundation
import CodeEditLanguages
import SwiftTreeSitter

/// `TreeSitterClient` is a class that manages applying edits for and querying captures for a syntax tree.
/// It handles queuing edits, processing them with the given text, and invalidating indices in the text for efficient
/// highlighting.
///
/// Use the `init` method to set up the client initially. If text changes it should be able to be read through the
/// `textProvider` callback. You can optionally update the text manually using the `setText` method.
/// However, the `setText` method will re-compile the entire corpus so should be used sparingly.
final class TreeSitterClient: HighlightProviding {

    typealias AsyncCallback = @Sendable () -> Void

    // MARK: - Properties/Constants

    public var identifier: String {
        "CodeEdit.TreeSitterClient"
    }

    internal weak var textView: HighlighterTextView?
    internal var readBlock: Parser.ReadBlock?

    internal var runningTask: Task<Void, Never>?
    internal var stateLock: NSLock = NSLock()
    internal var queueLock: NSLock = NSLock()
    internal var queuedEdits: [AsyncCallback] = []
    internal var queuedQueries: [AsyncCallback] = []

    internal var state: TreeSitterState
    internal var textProvider: ResolvingQueryCursor.TextProvider

    internal enum Constants {
        /// The maximum amount of limits a cursor can match during a query.
        /// Used to ensure performance in large files, even though we generally limit the query to the visible range.
        /// Neovim encountered this issue and uses 64 for their limit. Helix uses 256 due to issues with some
        /// languages when using 64.
        /// See: https://github.com/neovim/neovim/issues/14897
        /// And: https://github.com/helix-editor/helix/pull/4830
        static let treeSitterMatchLimit = 256

        /// The timeout for parsers.
        static let parserTimeout: TimeInterval = 0.005

        /// The maximum length of an edit before it must be processed asynchronously
        static let maxSyncEditLength: Int = 1024

        /// The maximum length a document can be before all queries and edits must be processed asynchronously.
        static let maxSyncContentLength: Int = 1_000_000

        /// The maximum length a query can be before it must be performed asynchronously.
        static let maxSyncQueryLength: Int = 4096
    }

    // MARK: - Init/Config

    /// Initializes the `TreeSitterClient` with the given parameters.
    /// - Parameters:
    ///   - codeLanguage: The language to set up the parser with.
    ///   - textProvider: The text provider callback to read any text.
    public init(codeLanguage: CodeLanguage, textProvider: @escaping ResolvingQueryCursor.TextProvider) {
        self.textProvider = textProvider
        self.state = TreeSitterState(primaryLayer: codeLanguage.id)
        self.setLanguage(codeLanguage: codeLanguage)
    }

    /// Sets the primary language for the client. Will reset all layers, will not do any parsing work.
    /// - Parameter codeLanguage: The new primary language.
    public func setLanguage(codeLanguage: CodeLanguage) {
        cancelAllRunningTasks()
        state.setLanguage(codeLanguage: codeLanguage)
    }

    // MARK: - HighlightProviding

    /// Set up and parse the initial language tree and all injected layers.
    func setUp(textView: HighlighterTextView) {
        cancelAllRunningTasks()

        self.textView = textView
        readBlock = textView.createReadBlock()

        state.setUp(textView: textView)
    }

    /// Notifies the highlighter of an edit and in exchange gets a set of indices that need to be re-highlighted.
    /// The returned `IndexSet` should include all indexes that need to be highlighted, including any inserted text.
    /// - Parameters:
    ///   - textView:The text view to use.
    ///   - range: The range of the edit.
    ///   - delta: The length of the edit, can be negative for deletions.
    ///   - completion: The function to call with an `IndexSet` containing all Indices to invalidate.
    func applyEdit(
        textView: HighlighterTextView,
        range: NSRange,
        delta: Int,
        completion: @escaping ((IndexSet) -> Void)
    ) {
        print("Received Edit", range, delta)
        guard let edit = InputEdit(range: range, delta: delta, oldEndPoint: .zero) else { return }

        queueLock.lock()
        let longEdit = range.length > Constants.maxSyncEditLength
        let longDocument = textView.documentRange.length > Constants.maxSyncContentLength

        if hasOutstandingWork || longEdit || longDocument {
            print("\tQueueing Async")
            applyEditAsync(editState: EditState(edit: edit, completion: completion), startAtLayerIndex: 0)
            queueLock.unlock()
        } else {
            queueLock.unlock()
            print("Performing Sync")
            applyEdit(editState: EditState(edit: edit, completion: completion))
        }
    }

    /// Initiates a highlight query.
    /// - Parameters:
    ///   - textView: The text view to use.
    ///   - range: The range to limit the highlights to.
    ///   - completion: Called when the query completes.
    func queryHighlightsFor(
        textView: HighlighterTextView,
        range: NSRange,
        completion: @escaping (([HighlightRange]) -> Void)
    ) {
        print("Received Query", range)
        queueLock.lock()
        let longQuery = range.length > Constants.maxSyncQueryLength
        let longDocument = textView.documentRange.length > Constants.maxSyncContentLength

        if hasOutstandingWork || longQuery || longDocument {
            print("\tQueuing Async Query")
            queryHighlightsForRangeAsync(range: range, completion: completion)
            queueLock.unlock()
        } else {
            queueLock.unlock()
            print("\tQueuing Sync Query")
            queryHighlightsForRange(range: range, runningAsync: false, completion: completion)
        }
    }

    // MARK: - Async Helpers

    var hasOutstandingWork: Bool {
        runningTask != nil || queuedEdits.count > 0 || queuedQueries.count > 0
    }

    /// Spawn the running task if one is needed and doesn't already exist.
    internal func beginTasksIfNeeded() {
        guard runningTask == nil && (queuedEdits.count > 0 || queuedQueries.count > 0) else { return }
        runningTask = Task.detached(priority: .userInitiated) {
            defer {
                self.runningTask = nil
            }

            var info = mach_timebase_info()
            guard mach_timebase_info(&info) == KERN_SUCCESS else { return }

            let start = mach_absolute_time()

            do {
                while let nextQueuedTask = self.determineNextTask() {
                    let end = mach_absolute_time()

                    let elapsed = end - start

                    let nanos = elapsed * UInt64(info.numer) / UInt64(info.denom)

                    print("\t\tFound Next Task. Tasks Remaining:", self.queuedEdits.count + self.queuedQueries.count)
                    print("\t\tTime Since queue started (ms): ", TimeInterval(nanos) / TimeInterval(NSEC_PER_MSEC))
                    try Task.checkCancellation()
                    nextQueuedTask()
                }
            } catch { }
        }
    }

    /// Determines the next async task to run and returns it if it exists.
    private func determineNextTask() -> AsyncCallback? {
        queueLock.lock()
        defer {
            queueLock.unlock()
        }

        // Get an edit task if any, otherwise get a highlight task if any.
        if queuedEdits.count > 0 {
            return queuedEdits.removeFirst()
        } else if queuedQueries.count > 0 {
            return queuedQueries.removeFirst()
        } else {
            return nil
        }
    }

    /// Cancels all running and enqueued tasks.
    private func cancelAllRunningTasks() {
        runningTask?.cancel()
        queuedEdits.removeAll()
        queuedQueries.removeAll()
    }
}
