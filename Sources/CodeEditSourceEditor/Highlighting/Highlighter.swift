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
import OSLog

/*
 +---------------------------------+
 |          Highlighter            |
 |                                 |
 |  - highlightProviders[]         |
 |  - styledRangeContainer         |
 |                                 |
 |  + refreshHighlightsIn(range:)  |
 +---------------------------------+
 |
 |
 v
 +-------------------------------+             +-----------------------------+
 |    RangeCaptureContainer      |   ------>   |         RangeStore          |
 |                               |             |                             |
 |  - manages combined ranges    |             |  - stores raw ranges &      |
 |  - layers highlight styles    |             |    captures                 |
 |  + getAttributesForRange()    |             +-----------------------------+
 +-------------------------------+
 ^
 |
 |
 +-------------------------------+
 |   HighlightProviderState[]    |   (one for each provider)
 |                               |
 |  - keeps valid/invalid ranges |
 |  - queries providers (async)  |
 |  + updateStyledRanges()       |
 +-------------------------------+
 ^
 |
 |
 +-------------------------------+
 |   HighlightProviding Object   |  (tree-sitter, LSP, spellcheck)
 +-------------------------------+
 */

/// The `Highlighter` class handles efficiently highlighting the `TextView` it's provided with.
/// It will listen for text and visibility changes, and highlight syntax as needed.
///
/// One should rarely have to directly modify or call methods on this class. Just keep it alive in
/// memory and it will listen for bounds changes, text changes, etc. However, to completely invalidate all
/// highlights use the ``invalidate()`` method to re-highlight all (visible) text, and the ``setLanguage``
/// method to update the highlighter with a new language if needed.
@MainActor
class Highlighter: NSObject {
    static private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "", category: "Highlighter")

    /// The current language of the editor.
    private var language: CodeLanguage

    /// The text view to highlight
    private weak var textView: TextView?

    /// The object providing attributes for captures.
    private weak var attributeProvider: ThemeAttributesProviding?

    private var styleContainer: StyledRangeContainer

    private var highlightProviders: [HighlightProviderState] = []

    private var visibleRangeProvider: VisibleRangeProvider

    // MARK: - Init

    init(
        textView: TextView,
        providers: [HighlightProviding],
        attributeProvider: ThemeAttributesProviding,
        language: CodeLanguage
    ) {
        self.language = language
        self.textView = textView
        self.attributeProvider = attributeProvider

        visibleRangeProvider = VisibleRangeProvider(textView: textView)

        let providerIds = providers.indices.map({ $0 })
        styleContainer = StyledRangeContainer(documentLength: textView.length, providers: providerIds)

        super.init()

        styleContainer.delegate = self
        visibleRangeProvider.delegate = self
        self.highlightProviders = providers.enumerated().map { (idx, provider) in
            HighlightProviderState(
                id: providerIds[idx],
                delegate: styleContainer,
                highlightProvider: provider,
                textView: textView,
                visibleRangeProvider: visibleRangeProvider,
                language: language
            )
        }
    }

    // MARK: - Public

    /// Invalidates all text in the editor. Useful for updating themes.
    public func invalidate() {
        highlightProviders.forEach { $0.invalidate() }
    }

    /// Sets the language and causes a re-highlight of the entire text.
    /// - Parameter language: The language to update to.
    public func setLanguage(language: CodeLanguage) {
        guard let textView = self.textView else { return }

        // Remove all current highlights. Makes the language setting feel snappier and tells the user we're doing
        // something immediately.
        textView.textStorage.setAttributes(
            attributeProvider?.attributesFor(nil) ?? [:],
            range: NSRange(location: 0, length: textView.textStorage.length)
        )
        textView.layoutManager.invalidateLayoutForRect(textView.visibleRect)

        highlightProviders.forEach { $0.setLanguage(language: language) }
    }

    deinit {
        self.attributeProvider = nil
        self.textView = nil
        self.highlightProviders = []
    }
}

// MARK: NSTextStorageDelegate

extension Highlighter: @preconcurrency NSTextStorageDelegate {
    /// Processes an edited range in the text.
    func textStorage(
        _ textStorage: NSTextStorage,
        didProcessEditing editedMask: NSTextStorageEditActions,
        range editedRange: NSRange,
        changeInLength delta: Int
    ) {
        // This method is called whenever attributes are updated, so to avoid re-highlighting the entire document
        // each time an attribute is applied, we check to make sure this is in response to an edit.
        guard editedMask.contains(.editedCharacters), let textView else { return }
        if delta > 0 {
            visibleRangeProvider.visibleSet.insert(range: editedRange)
        }

        visibleRangeProvider.updateVisibleSet(textView: textView)

        let styleContainerRange: Range<Int>
        let newLength: Int

        if editedRange.length == 0 { // Deleting, editedRange is at beginning of the range that was deleted
            styleContainerRange = editedRange.location..<(editedRange.location - delta)
            newLength = 0
        } else { // Replacing or inserting
            styleContainerRange = editedRange.location..<(editedRange.location + editedRange.length - delta)
            newLength = editedRange.length
        }

        styleContainer.storageUpdated(
            replacedContentIn: styleContainerRange,
            withCount: newLength
        )

        let providerRange = NSRange(location: editedRange.location, length: editedRange.length - delta)
        highlightProviders.forEach { $0.storageDidUpdate(range: providerRange, delta: delta) }
    }

    func textStorage(
        _ textStorage: NSTextStorage,
        willProcessEditing editedMask: NSTextStorageEditActions,
        range editedRange: NSRange,
        changeInLength delta: Int
    ) {
        guard editedMask.contains(.editedCharacters) else { return }
        highlightProviders.forEach { $0.storageWillUpdate(in: editedRange) }
    }
}

// MARK: - StyledRangeContainerDelegate

extension Highlighter: StyledRangeContainerDelegate {
    func styleContainerDidUpdate(in range: NSRange) {
        guard let textView, let attributeProvider else { return }
        textView.textStorage.beginEditing()

        let storage = textView.textStorage

        var offset = range.location
        for run in styleContainer.runsIn(range: range) {
            let range = NSRange(location: offset, length: run.length)
            storage?.setAttributes(attributeProvider.attributesFor(run.capture), range: range)
            offset += run.length
        }

        textView.textStorage.endEditing()
        textView.layoutManager.invalidateLayoutForRange(range)
    }
}

// MARK: - VisibleRangeProviderDelegate

extension Highlighter: VisibleRangeProviderDelegate {
    func visibleSetDidUpdate(_ newIndices: IndexSet) {
        highlightProviders.forEach { $0.invalidate(newIndices) }
    }
}
