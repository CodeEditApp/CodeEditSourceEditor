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

    private var rangeContainer: StyledRangeContainer

    private var providers: [HighlightProviderState] = []

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
        self.visibleRangeProvider = VisibleRangeProvider(textView: textView)

        let providerIds = providers.indices.map({ $0 })
        self.rangeContainer = StyledRangeContainer(documentLength: textView.length, providers: providerIds)

        super.init()

        self.providers = providers.enumerated().map { (idx, provider) in
            HighlightProviderState(
                id: providerIds[idx],
                delegate: rangeContainer,
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
        providers.forEach { $0.invalidate() }
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

        providers.forEach { $0.setLanguage(language: language) }
    }

    deinit {
        self.attributeProvider = nil
        self.textView = nil
        self.providers = []
    }
}

extension Highlighter: NSTextStorageDelegate {
    /// Processes an edited range in the text.
    /// Will query tree-sitter for any updated indices and re-highlight only the ranges that need it.
    func textStorage(
        _ textStorage: NSTextStorage,
        didProcessEditing editedMask: NSTextStorageEditActions,
        range editedRange: NSRange,
        changeInLength delta: Int
    ) {
        // This method is called whenever attributes are updated, so to avoid re-highlighting the entire document
        // each time an attribute is applied, we check to make sure this is in response to an edit.
        guard editedMask.contains(.editedCharacters) else { return }

//        self.storageDidEdit(editedRange: editedRange, delta: delta)
    }

    func textStorage(
        _ textStorage: NSTextStorage,
        willProcessEditing editedMask: NSTextStorageEditActions,
        range editedRange: NSRange,
        changeInLength delta: Int
    ) {
        guard editedMask.contains(.editedCharacters) else { return }
//        self.storageWillEdit(editedRange: editedRange)
    }
}
