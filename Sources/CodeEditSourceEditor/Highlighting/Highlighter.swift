//
//  Highlighter.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 9/12/22.
//

import Foundation
import AppKit
import CodeEditTextView
import SwiftTreeSitter
import CodeEditLanguages

/// The `Highlighter` class handles efficiently highlighting the `TextView` it's provided with.
/// It will listen for text and visibility changes, and highlight syntax as needed.
///
/// One should rarely have to direcly modify or call methods on this class. Just keep it alive in
/// memory and it will listen for bounds changes, text changes, etc. However, to completely invalidate all
/// highlights use the ``invalidate()`` method to re-highlight all (visible) text, and the ``setLanguage``
/// method to update the highlighter with a new language if needed.
@MainActor
class Highlighter: NSObject {

    // MARK: - Index Sets

    /// Any indexes that highlights have been requested for, but haven't been applied.
    /// Indexes/ranges are added to this when highlights are requested and removed
    /// after they are applied
    private var pendingSet: IndexSet = .init()

    /// The set of valid indexes
    private var validSet: IndexSet = .init()

    /// The set of visible indexes in tht text view
    lazy private var visibleSet: IndexSet = {
        return IndexSet(integersIn: textView?.visibleTextRange ?? NSRange())
    }()

    // MARK: - Tasks

    private var runningTasks: [UUID: Task<Void, Never>] = [:]

    // MARK: - UI

    /// The text view to highlight
    private weak var textView: TextView?

    /// The editor theme
    private var theme: EditorTheme

    /// The object providing attributes for captures.
    private weak var attributeProvider: ThemeAttributesProviding!

    /// The current language of the editor.
    private var language: CodeLanguage

    /// Calculates invalidated ranges given an edit.
    private(set) weak var highlightProvider: HighlightProviding?

    /// The length to chunk ranges into when passing to the highlighter.
    private let rangeChunkLimit = 256

    // MARK: - Init

    /// Initializes the `Highlighter`
    /// - Parameters:
    ///   - textView: The text view to highlight.
    ///   - treeSitterClient: The tree-sitter client to handle tree updates and highlight queries.
    ///   - theme: The theme to use for highlights.
    init(
        textView: TextView,
        highlightProvider: HighlightProviding?,
        theme: EditorTheme,
        attributeProvider: ThemeAttributesProviding,
        language: CodeLanguage
    ) {
        self.textView = textView
        self.highlightProvider = highlightProvider
        self.theme = theme
        self.attributeProvider = attributeProvider
        self.language = language

        super.init()

        addTask {
            await highlightProvider?.setUp(textView: textView, codeLanguage: language)
            return
        }

        if let scrollView = textView.enclosingScrollView {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(visibleTextChanged(_:)),
                name: NSView.frameDidChangeNotification,
                object: scrollView
            )

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(visibleTextChanged(_:)),
                name: NSView.boundsDidChangeNotification,
                object: scrollView.contentView
            )
        }
    }

    // MARK: - Public

    /// Invalidates all text in the textview. Useful for updating themes.
    public func invalidate() {
        guard let textView else { return }
        updateVisibleSet(textView: textView)
        invalidate(range: textView.documentRange)
    }

    /// Sets the language and causes a re-highlight of the entire text.
    /// - Parameter language: The language to update to.
    public func setLanguage(language: CodeLanguage) {
        cancelAllTasks()

        addTask {
            guard let textView = self.textView else { return }
            await self.highlightProvider?.setUp(textView: textView, codeLanguage: language)
            guard !Task.isCancelled else { return }
            self.invalidate()
        }
    }

    /// Sets the highlight provider. Will cause a re-highlight of the entire text.
    /// - Parameter provider: The provider to use for future syntax highlights.
    public func setHighlightProvider(_ provider: HighlightProviding) {
        cancelAllTasks()

        highlightProvider = provider
        addTask {
            guard let textView = self.textView else { return }
            await self.highlightProvider?.setUp(textView: textView, codeLanguage: self.language)
            guard !Task.isCancelled else { return }
            self.invalidate()
        }
    }

    /// Add a task to the set of tracked tasks for this highlighter.
    ///
    /// This method wraps the operation in a task that will remove itself from the list of running tasks, allowing
    /// this class to track and cancel tasks itself.
    ///
    /// - Parameters:
    ///   - detached: Set to true to detach the task from the current context.
    ///   - operation: The operation to perform asynchronously.
    func addTask(detached: Bool = false, operation: @MainActor @Sendable @escaping () async -> Void) {
        // Add the new task to the running tasks list.
        let taskId = UUID()
        let newTask = Task {
            await operation()
            runningTasks.removeValue(forKey: taskId)
        }
        runningTasks[taskId] = newTask
    }

    func cancelAllTasks() {
        for task in runningTasks.values {
            task.cancel()
        }
        runningTasks.removeAll()
    }

    deinit {
        for task in runningTasks.values {
            task.cancel()
        }
        runningTasks.removeAll()
        self.attributeProvider = nil
        self.textView = nil
        self.highlightProvider = nil
    }
}

// MARK: - Highlighting

private extension Highlighter {

    /// Invalidates a given range and adds it to the queue to be highlighted.
    /// - Parameter range: The range to invalidate.
    func invalidate(range: NSRange) {
        let set = IndexSet(integersIn: range)

        if set.isEmpty {
            return
        }

        validSet.subtract(set)

        highlightInvalidRanges()
    }

    /// Begins highlighting any invalid ranges
    func highlightInvalidRanges() {
        // If there aren't any more ranges to highlight, don't do anything, otherwise continue highlighting
        // any available ranges.
        var rangesToQuery: [NSRange] = []
        while let range = getNextRange() {
            rangesToQuery.append(range)
            pendingSet.insert(range: range)
        }

        queryHighlights(for: rangesToQuery)
    }

    /// Highlights the given ranges
    /// - Parameter ranges: The ranges to request highlights for.
    func queryHighlights(for rangesToHighlight: [NSRange]) {
        for range in rangesToHighlight {
            pendingSet.insert(integersIn: range)
        }
        addTask(detached: true) {
            await withTaskGroup(of: Void.self) { group in
                for range in rangesToHighlight {
                    group.addTask { [weak self] in
                        guard let textView = await self?.textView else { return }

                        let highlights = await self?.highlightProvider?.queryHighlightsFor(
                            textView: textView,
                            range: range
                        )

                        guard !Task.isCancelled else { return }

                        await self?.applyHighlightResult(highlights ?? [], rangeToHighlight: range)
                    }
                }
            }
        }
    }

    /// Applies a highlight query result to the text view.
    /// - Parameters:
    ///   - results: The result of a highlight query.
    ///   - rangeToHighlight: The range to apply the highlight to.
    @MainActor
    private func applyHighlightResult(_ results: [HighlightRange], rangeToHighlight: NSRange) {
        guard let attributeProvider = self.attributeProvider else {
            return
        }

        pendingSet.remove(integersIn: rangeToHighlight)
        guard visibleSet.intersects(integersIn: rangeToHighlight) else {
            return
        }
        validSet.formUnion(IndexSet(integersIn: rangeToHighlight))

        // Loop through each highlight and modify the textStorage accordingly.
        textView?.layoutManager.beginTransaction()
        textView?.textStorage.beginEditing()

        // Create a set of indexes that were not highlighted.
        var ignoredIndexes = IndexSet(integersIn: rangeToHighlight)

        // Apply all highlights that need color
        for highlight in results {
            textView?.textStorage.setAttributes(
                attributeProvider.attributesFor(highlight.capture),
                range: highlight.range
            )

            // Remove highlighted indexes from the "ignored" indexes.
            ignoredIndexes.remove(integersIn: highlight.range)
        }

        // For any indices left over, we need to apply normal attributes to them
        // This fixes the case where characters are changed to have a non-text color, and then are skipped when
        // they need to be changed back.
        for ignoredRange in ignoredIndexes.rangeView {
            textView?.textStorage.setAttributes(
                attributeProvider.attributesFor(nil),
                range: NSRange(ignoredRange)
            )
        }

        textView?.textStorage.endEditing()
        textView?.layoutManager.endTransaction()
    }

    /// Gets the next `NSRange` to highlight based on the invalid set, visible set, and pending set.
    /// - Returns: An `NSRange` to highlight if it could be fetched.
    func getNextRange() -> NSRange? {
        let set: IndexSet = IndexSet(integersIn: textView?.documentRange ?? .zero) // All text
            .subtracting(validSet) // Subtract valid = Invalid set
            .intersection(visibleSet) // Only visible indexes
            .subtracting(pendingSet) // Don't include pending indexes

        guard let range = set.rangeView.first else {
            return nil
        }

        // Chunk the ranges in sets of rangeChunkLimit characters.
        return NSRange(
            location: range.lowerBound,
            length: min(rangeChunkLimit, range.upperBound - range.lowerBound)
        )
    }

}

// MARK: - Visible Content Updates

private extension Highlighter {
    private func updateVisibleSet(textView: TextView) {
        if let newVisibleRange = textView.visibleTextRange {
            visibleSet = IndexSet(integersIn: newVisibleRange)
        }
    }

    /// Updates the view to highlight newly visible text when the textview is scrolled or bounds change.
    @objc func visibleTextChanged(_ notification: Notification) {
        guard let clipView = notification.object as? NSClipView,
              let textView = clipView.enclosingScrollView?.documentView as? TextView else {
            return
        }
        updateVisibleSet(textView: textView)

        // Any indices that are both *not* valid and in the visible text range should be invalidated
        let newlyInvalidSet = visibleSet.subtracting(validSet)

        for range in newlyInvalidSet.rangeView.map({ NSRange($0) }) {
            invalidate(range: range)
        }
    }
}

// MARK: - Editing

extension Highlighter {
    func storageDidEdit(editedRange: NSRange, delta: Int) async {
        guard let textView else { return }

        let range = NSRange(location: editedRange.location, length: editedRange.length - delta)
        if delta > 0 {
            visibleSet.insert(range: editedRange)
        }

        guard let invalidatedIndexSet = await highlightProvider?.applyEdit(
            textView: textView,
            range: range,
            delta: delta
        ) else {
            return
        }

        let indexSet = invalidatedIndexSet
            .union(IndexSet(integersIn: editedRange))
            // Only invalidate indices that are visible.
            .intersection(visibleSet)

        for range in indexSet.rangeView {
            invalidate(range: NSRange(range))
        }
    }

    func storageWillEdit(editedRange: NSRange) async {
        guard let textView else { return }
        await highlightProvider?.willApplyEdit(textView: textView, range: editedRange)
    }
}
