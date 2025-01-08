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

/// This class manages fetching syntax highlights from providers, and applying those styles to the editor.
/// Multiple highlight providers can be used to style the editor.
///
/// This class manages multiple objects that help perform this task:
/// - ``StyledRangeContainer``
/// - ``StyledRangeStore``
/// - ``VisibleRangeProvider``
/// - ``HighlightProviderState``
///
/// A hierarchal overview of the highlighter system.
/// ```
/// +---------------------------------+
/// |          Highlighter            |
/// |                                 |
/// |  - highlightProviders[]         |
/// |  - styledRangeContainer         |
/// |                                 |
/// |  + refreshHighlightsIn(range:)  |
/// +---------------------------------+
/// |
/// | Queries coalesced styles
/// v
/// +-------------------------------+             +-----------------------------+
/// |    StyledRangeContainer       |   ------>   |      StyledRangeStore[]     |
/// |                               |             |                             | Stores styles for one provider
/// |  - manages combined ranges    |             |  - stores raw ranges &      |
/// |  - layers highlight styles    |             |    captures                 |
/// |  + getAttributesForRange()    |             +-----------------------------+
/// +-------------------------------+
/// ^
/// | Sends highlighted runs
/// |
/// +-------------------------------+
/// |   HighlightProviderState[]    |   (one for each provider)
/// |                               |
/// |  - keeps valid/invalid ranges |
/// |  - queries providers (async)  |
/// |  + updateStyledRanges()       |
/// +-------------------------------+
/// ^
/// | Performs edits and sends highlight deltas, as well as calculates syntax captures for ranges
/// |
/// +-------------------------------+
/// |   HighlightProviding Object   |  (tree-sitter, LSP, spellcheck)
/// +-------------------------------+
/// ```
///
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

    public func invalidate(_ set: IndexSet) {
        highlightProviders.forEach { $0.invalidate(set) }
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

extension Highlighter: NSTextStorageDelegate {
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

        if delta > 0 {
            visibleRangeProvider.visibleSet.insert(range: editedRange)
        }

        visibleRangeProvider.updateVisibleSet(textView: textView)

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
        textView.layoutManager.beginTransaction()
        textView.textStorage.beginEditing()

        let storage = textView.textStorage

        var offset = range.location
        for run in styleContainer.runsIn(range: range) {
            guard let range = NSRange(location: offset, length: run.length).intersection(range) else {
                continue
            }
            storage?.setAttributes(attributeProvider.attributesFor(run.capture), range: range)
            offset += range.length
        }

        textView.textStorage.endEditing()
        textView.layoutManager.endTransaction()
        textView.layoutManager.invalidateLayoutForRange(range)
    }
}

// MARK: - VisibleRangeProviderDelegate

extension Highlighter: VisibleRangeProviderDelegate {
    func visibleSetDidUpdate(_ newIndices: IndexSet) {
        highlightProviders.forEach { $0.highlightInvalidRanges() }
    }
}
