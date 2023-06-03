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
public final class TreeSitterClient: HighlightProviding {
    typealias AsyncCallback = @Sendable () -> Void

    // MARK: - Properties

    public var identifier: String {
        "CodeEdit.TreeSitterClient"
    }

    /// The text view to use as a data source for text.
    internal weak var textView: HighlighterTextView?
    /// A callback to use to efficiently fetch portions of text.
    internal var readBlock: Parser.ReadBlock?

    /// The running background task.
    internal var runningTask: Task<Void, Never>?
    /// An array of all edits queued for execution.
    internal var queuedEdits: [AsyncCallback] = []
    /// An array of all highlight queries queued for execution.
    internal var queuedQueries: [AsyncCallback] = []

    /// A lock that must be obtained whenever `state` is modified
    internal var stateLock: PthreadLock = PthreadLock()
    /// A lock that must be obtained whenever either `queuedEdits` or `queuedHighlights` is modified
    internal var queueLock: PthreadLock = PthreadLock()

    /// The internal tree-sitter layer tree object.
    internal var state: TreeSitterState?
    internal var textProvider: ResolvingQueryCursor.TextProvider

    // MARK: - Constants

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

        /// The maximum number of highlight queries that can be performed in parallel.
        static let simultaneousHighlightLimit: Int = 5
    }

    // MARK: - Init/Config

    /// Initializes the `TreeSitterClient` with the given parameters.
    /// - Parameters:
    ///   - textView: The text view to use as a data source.
    ///   - codeLanguage: The language to set up the parser with.
    ///   - textProvider: The text provider callback to read any text.
    public init(textProvider: @escaping ResolvingQueryCursor.TextProvider) {
        self.textProvider = textProvider
    }

    // MARK: - HighlightProviding

    /// Set up the client with a text view and language.
    /// - Parameters:
    ///   - textView: The text view to use as a data source.
    ///               A weak reference will be kept for the lifetime of this object.
    ///   - codeLanguage: The language to use for parsing.
    public func setUp(textView: HighlighterTextView, codeLanguage: CodeLanguage) {
        cancelAllRunningTasks()
        queueLock.lock()
        self.textView = textView
        self.readBlock = textView.createReadBlock()
        queuedEdits.append {
            self.stateLock.lock()
            if self.state == nil {
                self.state = TreeSitterState(codeLanguage: codeLanguage, textView: textView)
            } else {
                self.state?.setLanguage(codeLanguage)
            }
            self.stateLock.unlock()
        }
        beginTasksIfNeeded()
        queueLock.unlock()
    }

    /// Notifies the highlighter of an edit and in exchange gets a set of indices that need to be re-highlighted.
    /// The returned `IndexSet` should include all indexes that need to be highlighted, including any inserted text.
    /// - Parameters:
    ///   - textView:The text view to use.
    ///   - range: The range of the edit.
    ///   - delta: The length of the edit, can be negative for deletions.
    ///   - completion: The function to call with an `IndexSet` containing all Indices to invalidate.
    public func applyEdit(
        textView: HighlighterTextView,
        range: NSRange,
        delta: Int,
        completion: @escaping ((IndexSet) -> Void)
    ) {
        guard let edit = InputEdit(range: range, delta: delta, oldEndPoint: .zero) else { return }

        queueLock.lock()
        let longEdit = range.length > Constants.maxSyncEditLength
        let longDocument = textView.documentRange.length > Constants.maxSyncContentLength

        if hasOutstandingWork || longEdit || longDocument {
            applyEditAsync(editState: EditState(edit: edit, completion: completion), startAtLayerIndex: 0)
            queueLock.unlock()
        } else {
            queueLock.unlock()
            applyEdit(editState: EditState(edit: edit, completion: completion))
        }
    }

    /// Initiates a highlight query.
    /// - Parameters:
    ///   - textView: The text view to use.
    ///   - range: The range to limit the highlights to.
    ///   - completion: Called when the query completes.
    public func queryHighlightsFor(
        textView: HighlighterTextView,
        range: NSRange,
        completion: @escaping (([HighlightRange]) -> Void)
    ) {
        queueLock.lock()
        let longQuery = range.length > Constants.maxSyncQueryLength
        let longDocument = textView.documentRange.length > Constants.maxSyncContentLength

        if hasOutstandingWork || longQuery || longDocument {
            queryHighlightsForRangeAsync(range: range, completion: completion)
            queueLock.unlock()
        } else {
            queueLock.unlock()
            queryHighlightsForRange(range: range, runningAsync: false, completion: completion)
        }
    }

    // MARK: - Async

    /// Use to determine if there are any queued or running async tasks.
    var hasOutstandingWork: Bool {
        runningTask != nil || queuedEdits.count > 0 || queuedQueries.count > 0
    }

    private enum QueuedTaskType {
        case edit(job: AsyncCallback)
        case highlight(jobs: [AsyncCallback])
    }

    /// Spawn the running task if one is needed and doesn't already exist.
    ///
    /// The task will run until `determineNextTask` returns nil. It will run any highlight jobs in parallel.
    internal func beginTasksIfNeeded() {
        guard runningTask == nil && (queuedEdits.count > 0 || queuedQueries.count > 0) else { return }
        runningTask = Task.detached(priority: .userInitiated) {
            defer {
                self.runningTask = nil
            }

            do {
                while let nextQueuedJob = self.determineNextJob() {
                    try Task.checkCancellation()
                    switch nextQueuedJob {
                    case .edit(let job):
                        job()
                    case .highlight(let jobs):
                        await withTaskGroup(of: Void.self, body: { taskGroup in
                            for job in jobs {
                                taskGroup.addTask {
                                    job()
                                }
                            }
                        })
                    }
                }
            } catch { }
        }
    }

    /// Determines the next async job to run and returns it if it exists.
    /// Greedily returns queued highlight jobs determined by `Constants.simultaneousHighlightLimit`
    private func determineNextJob() -> QueuedTaskType? {
        queueLock.lock()
        defer {
            queueLock.unlock()
        }

        // Get an edit task if any, otherwise get a highlight task if any.
        if queuedEdits.count > 0 {
            return .edit(job: queuedEdits.removeFirst())
        } else if queuedQueries.count > 0 {
            let jobCount = min(queuedQueries.count, Constants.simultaneousHighlightLimit)
            let jobs = Array(queuedQueries[0..<jobCount])
            queuedQueries.removeFirst(jobCount)
            return .highlight(jobs: jobs)
        } else {
            return nil
        }
    }

    /// Cancels all running and enqueued tasks.
    private func cancelAllRunningTasks() {
        queueLock.lock()
        runningTask?.cancel()
        queuedEdits.removeAll()
        queuedQueries.removeAll()
        queueLock.unlock()
    }

    deinit {
        cancelAllRunningTasks()
    }
}
