//
//  Highlighter.swift
//
//
//  Created by Khan Winter on 9/12/22.
//

import Foundation
import AppKit
import STTextView
import SwiftTreeSitter
import CodeEditLanguages

/// The `Highlighter` class handles efficiently highlighting the `STTextView` it's provided with.
/// It will listen for text and visibility changes, and highlight syntax as needed.
///
/// One should rarely have to direcly modify or call methods on this class. Just keep it alive in
/// memory and it will listen for bounds changes, text changes, etc. However, to completely invalidate all
/// highlights use the ``invalidate()`` method to re-highlight all (visible) text, and the ``setLanguage``
/// method to update the highlighter with a new language if needed.
class Highlighter: NSObject {

    // MARK: - Index Sets

    /// Any indexes that highlights have been requested for, but haven't been applied.
    /// Indexes/ranges are added to this when highlights are requested and removed
    /// after they are applied
    private var pendingSet: IndexSet = .init()

    /// The set of valid indexes
    private var validSet: IndexSet = .init()

    /// The range of the entire document
    private var entireTextRange: Range<Int> {
        return 0..<(textView.textContentStorage?.textStorage?.length ?? 0)
    }

    /// The set of visible indexes in tht text view
    lazy private var visibleSet: IndexSet = {
        return IndexSet(integersIn: textView.visibleTextRange ?? NSRange())
    }()

    // MARK: - UI

    /// The text view to highlight
    private var textView: STTextView

    /// The editor theme
    private var theme: EditorTheme

    /// The object providing attributes for captures.
    private var attributeProvider: ThemeAttributesProviding!

    /// The current language of the editor.
    private var language: CodeLanguage

    /// Calculates invalidated ranges given an edit.
    private var highlightProvider: HighlightProviding?

    /// The length to chunk ranges into when passing to the highlighter.
    fileprivate let rangeChunkLimit = 256

    // MARK: - Init

    /// Initializes the `Highlighter`
    /// - Parameters:
    ///   - textView: The text view to highlight.
    ///   - treeSitterClient: The tree-sitter client to handle tree updates and highlight queries.
    ///   - theme: The theme to use for highlights.
    init(
        textView: STTextView,
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

        guard textView.textContentStorage?.textStorage != nil else {
            assertionFailure("Text view does not have a textStorage")
            return
        }

        textView.textContentStorage?.textStorage?.delegate = self
        highlightProvider?.setUp(textView: textView, codeLanguage: language)

        if let scrollView = textView.enclosingScrollView {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(visibleTextChanged(_:)),
                                                   name: NSView.frameDidChangeNotification,
                                                   object: scrollView)

            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(visibleTextChanged(_:)),
                                                   name: NSView.boundsDidChangeNotification,
                                                   object: scrollView.contentView)
        }
    }

    // MARK: - Public

    /// Invalidates all text in the textview. Useful for updating themes.
    public func invalidate() {
        updateVisibleSet()
        invalidate(range: NSRange(entireTextRange))
    }

    /// Sets the language and causes a re-highlight of the entire text.
    /// - Parameter language: The language to update to.
    public func setLanguage(language: CodeLanguage) {
        highlightProvider?.setUp(textView: textView, codeLanguage: language)
        invalidate()
    }

    /// Sets the highlight provider. Will cause a re-highlight of the entire text.
    /// - Parameter provider: The provider to use for future syntax highlights.
    public func setHighlightProvider(_ provider: HighlightProviding) {
        self.highlightProvider = provider
        highlightProvider?.setUp(textView: textView, codeLanguage: language)
        invalidate()
    }

    deinit {
        self.attributeProvider = nil
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

        highlightNextRange()
    }

    /// Begins highlighting any invalid ranges
    func highlightNextRange() {
        // If there aren't any more ranges to highlight, don't do anything, otherwise continue highlighting
        // any available ranges.
        guard let range = getNextRange() else {
            return
        }

        highlight(range: range)

        highlightNextRange()
    }

    /// Highlights the given range
    /// - Parameter range: The range to request highlights for.
    func highlight(range rangeToHighlight: NSRange) {
        pendingSet.insert(integersIn: rangeToHighlight)

        highlightProvider?.queryHighlightsFor(textView: self.textView,
                                              range: rangeToHighlight) { [weak self] highlightRanges in
            guard let attributeProvider = self?.attributeProvider,
                  let textView = self?.textView else { return }

            self?.pendingSet.remove(integersIn: rangeToHighlight)
            guard self?.visibleSet.intersects(integersIn: rangeToHighlight) ?? false else {
                return
            }
            self?.validSet.formUnion(IndexSet(integersIn: rangeToHighlight))

            // Try to create a text range for invalidating. If this fails we fail silently
            guard let textContentManager = textView.textLayoutManager.textContentManager,
                  let textRange = NSTextRange(rangeToHighlight, provider: textContentManager) else {
                return
            }

            // Loop through each highlight and modify the textStorage accordingly.
            textView.textContentStorage?.textStorage?.beginEditing()

            // Create a set of indexes that were not highlighted.
            var ignoredIndexes = IndexSet(integersIn: rangeToHighlight)

            // Apply all highlights that need color
            for highlight in highlightRanges {
                // Does not work:
//                textView.textLayoutManager.setRenderingAttributes(attributeProvider.attributesFor(highlight.capture),
//                                                                  for: NSTextRange(highlight.range,
//                                                                       provider: textView.textContentStorage)!)
                // Temp solution (until Apple fixes above)
                textView.textContentStorage?.textStorage?.setAttributes(
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
                textView.textContentStorage?.textStorage?.setAttributes(
                    attributeProvider.attributesFor(nil),
                    range: NSRange(ignoredRange)
                )
            }

            textView.textContentStorage?.textStorage?.endEditing()

            // After applying edits to the text storage we need to invalidate the layout
            // of the highlighted text.
            textView.textLayoutManager.invalidateLayout(for: textRange)
        }
    }

    /// Gets the next `NSRange` to highlight based on the invalid set, visible set, and pending set.
    /// - Returns: An `NSRange` to highlight if it could be fetched.
    func getNextRange() -> NSRange? {
        let set: IndexSet = IndexSet(integersIn: entireTextRange) // All text
            .subtracting(validSet) // Subtract valid = Invalid set
            .intersection(visibleSet) // Only visible indexes
            .subtracting(pendingSet) // Don't include pending indexes

        guard let range = set.rangeView.first else {
            return nil
        }

        // Chunk the ranges in sets of rangeChunkLimit characters.
        return NSRange(location: range.lowerBound,
                       length: min(rangeChunkLimit, range.upperBound - range.lowerBound))
    }

}

// MARK: - Visible Content Updates

private extension Highlighter {
    private func updateVisibleSet() {
        if let newVisibleRange = textView.visibleTextRange {
            visibleSet = IndexSet(integersIn: newVisibleRange)
        }
    }

    /// Updates the view to highlight newly visible text when the textview is scrolled or bounds change.
    @objc func visibleTextChanged(_ notification: Notification) {
        updateVisibleSet()

        // Any indices that are both *not* valid and in the visible text range should be invalidated
        let newlyInvalidSet = visibleSet.subtracting(validSet)

        for range in newlyInvalidSet.rangeView.map({ NSRange($0) }) {
            invalidate(range: range)
        }
    }
}

// MARK: - NSTextStorageDelegate

extension Highlighter: NSTextStorageDelegate {
    /// Processes an edited range in the text.
    /// Will query tree-sitter for any updated indices and re-highlight only the ranges that need it.
    func textStorage(_ textStorage: NSTextStorage,
                     didProcessEditing editedMask: NSTextStorageEditActions,
                     range editedRange: NSRange,
                     changeInLength delta: Int) {
        // This method is called whenever attributes are updated, so to avoid re-highlighting the entire document
        // each time an attribute is applied, we check to make sure this is in response to an edit.
        guard editedMask.contains(.editedCharacters) else {
            return
        }

        let range = NSRange(location: editedRange.location, length: editedRange.length - delta)
        if delta > 0 {
            visibleSet.insert(range: editedRange)
        }

        highlightProvider?.applyEdit(textView: self.textView,
                                     range: range,
                                     delta: delta) { [weak self] invalidatedIndexSet in
            let indexSet = invalidatedIndexSet
                .union(IndexSet(integersIn: editedRange))
                // Only invalidate indices that are visible.
                .intersection(self?.visibleSet ?? .init())

            for range in indexSet.rangeView {
                self?.invalidate(range: NSRange(range))
            }
        }
    }
}
