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

/// Classes conforming to this protocol can provide attributes for text given a capture type.
public protocol ThemeAttributesProviding {
    func attributesFor(_ capture: CaptureName?) -> [NSAttributedString.Key: Any]
}

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
        return 0..<(textView.textContentStorage.textStorage?.length ?? 0)
    }

    /// The set of visible indexes in tht text view
    lazy private var visibleSet: IndexSet = {
        return IndexSet(integersIn: Range(textView.visibleTextRange)!)
    }()

    // MARK: - UI

    /// The text view to highlight
    private var textView: STTextView
    private var theme: EditorTheme
    private var attributeProvider: ThemeAttributesProviding!

    // MARK: - TreeSitter Client

    /// Calculates invalidated ranges given an edit.
    private var treeSitterClient: TreeSitterClient?

    // MARK: - Init

    /// Initializes the `Highlighter`
    /// - Parameters:
    ///   - textView: The text view to highlight.
    ///   - treeSitterClient: The tree-sitter client to handle tree updates and highlight queries.
    ///   - theme: The theme to use for highlights.
    init(textView: STTextView,
         treeSitterClient: TreeSitterClient?,
         theme: EditorTheme,
         attributeProvider: ThemeAttributesProviding) {
        self.textView = textView
        self.treeSitterClient = treeSitterClient
        self.theme = theme
        self.attributeProvider = attributeProvider

        super.init()

        treeSitterClient?.setText(text: textView.string)

        guard textView.textContentStorage.textStorage != nil else {
            assertionFailure("Text view does not have a textStorage")
            return
        }

        textView.textContentStorage.textStorage?.delegate = self

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
    func invalidate() {
        if !(treeSitterClient?.hasSetText ?? true) {
            treeSitterClient?.setText(text: textView.string)
        }
        invalidate(range: entireTextRange)
    }

    /// Sets the language and causes a re-highlight of the entire text.
    /// - Parameter language: The language to update to.
    func setLanguage(language: CodeLanguage) throws {
        try treeSitterClient?.setLanguage(codeLanguage: language, text: textView.string)
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
        invalidate(range: Range(range)!)
    }

    /// Invalidates a given range and adds it to the queue to be highlighted.
    /// - Parameter range: The range to invalidate.
    func invalidate(range: Range<Int>) {
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
    func highlight(range nsRange: NSRange) {
        let range = Range(nsRange)!
        pendingSet.insert(integersIn: range)

        treeSitterClient?.queryColorsFor(range: nsRange) { [weak self] highlightRanges in
            guard let attributeProvider = self?.attributeProvider,
                  let textView = self?.textView else { return }

            // Mark these indices as not pending and valid
            self?.pendingSet.remove(integersIn: range)
            self?.validSet.formUnion(IndexSet(integersIn: range))

            // If this range does not exist in the visible set, we can exit.
            if !(self?.visibleSet ?? .init()).contains(integersIn: range) {
                return
            }

            // Try to create a text range for invalidating. If this fails we fail silently
            guard let textContentManager = textView.textLayoutManager.textContentManager,
                  let textRange = NSTextRange(nsRange, provider: textContentManager) else {
                return
            }

            // Loop through each highlight and modify the textStorage accordingly.
            textView.textContentStorage.textStorage?.beginEditing()
            for highlight in highlightRanges {
                textView.textContentStorage.textStorage?.setAttributes(
                    attributeProvider.attributesFor(highlight.capture),
                    range: highlight.range
                )
            }
            textView.textContentStorage.textStorage?.endEditing()

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

        guard let range = set.rangeView.map({ NSRange($0) }).first else {
            return nil
        }

        return range
    }

}

// MARK: - Visible Content Updates

private extension Highlighter {
    /// Updates the view to highlight newly visible text when the textview is scrolled or bounds change.
    @objc func visibleTextChanged(_ notification: Notification) {
        visibleSet = IndexSet(integersIn: Range(textView.visibleTextRange)!)

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

        guard let edit = InputEdit(range: range, delta: delta, oldEndPoint: .zero) else {
            return
        }

        treeSitterClient?.applyEdit(edit,
                                   text: textStorage.string) { [weak self] invalidatedIndexSet in
            let indexSet = invalidatedIndexSet
                .union(IndexSet(integersIn: Range(editedRange)!))
                // Only invalidate indices that aren't visible.
                .intersection(self?.visibleSet ?? .init())

            for range in indexSet.rangeView {
                self?.invalidate(range: NSRange(range))
            }
        }
    }
}
