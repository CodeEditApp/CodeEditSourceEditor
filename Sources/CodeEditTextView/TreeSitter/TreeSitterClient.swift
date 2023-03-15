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

    // MARK: - Properties/Constants

    public var identifier: String {
        "CodeEdit.TreeSitterClient"
    }

    internal var primaryLayer: TreeSitterLanguage
    internal var layers: [LanguageLayer] = []

    internal var textProvider: ResolvingQueryCursor.TextProvider

    /// The queue to do  tree-sitter work on for large edits/queries
    internal let queue: DispatchQueue = DispatchQueue(label: "CodeEdit.CodeEditTextView.TreeSitter",
                                                      qos: .userInteractive)

    /// Used to ensure safe use of the shared tree-sitter tree state in different sync/async contexts.
    internal let semaphore: DispatchSemaphore = DispatchSemaphore(value: 1)

    internal enum Constants {
        /// The maximum amount of limits a cursor can match during a query.
        /// Used to ensure performance in large files, even though we generally limit the query to the visible range.
        /// Neovim encountered this issue and uses 64 for their limit. Helix uses 256 due to issues with some
        /// languages when using 64.
        /// See: https://github.com/neovim/neovim/issues/14897
        /// And: https://github.com/helix-editor/helix/pull/4830
        static let treeSitterMatchLimit = 256
    }

    // MARK: - Init/Config

    /// Initializes the `TreeSitterClient` with the given parameters.
    /// - Parameters:
    ///   - codeLanguage: The language to set up the parser with.
    ///   - textProvider: The text provider callback to read any text.
    public init(codeLanguage: CodeLanguage, textProvider: @escaping ResolvingQueryCursor.TextProvider) throws {
        self.textProvider = textProvider
        self.primaryLayer = codeLanguage.id
        setLanguage(codeLanguage: codeLanguage)
    }

    /// Sets the primary language for the client. Will reset all layers, will not do any parsing work.
    /// - Parameter codeLanguage: The new primary language.
    public func setLanguage(codeLanguage: CodeLanguage) {
        // Remove all trees and languages, everything needs to be re-parsed.
        layers.removeAll()

        primaryLayer = codeLanguage.id
        layers = [
            LanguageLayer(id: codeLanguage.id,
                          parser: Parser(),
                          tree: nil,
                          languageQuery: TreeSitterModel.shared.query(for: codeLanguage.id),
                          ranges: [])
        ]

        if let treeSitterLanguage = codeLanguage.language {
            try? layers[0].parser.setLanguage(treeSitterLanguage)
        }
    }

    // MARK: - HighlightProviding

    /// Set up and parse the initial language tree and all injected layers.
    func setUp(textView: HighlighterTextView) {
        let readBlock = createReadBlock(textView: textView)

        layers[0].tree = createTree(parser: layers[0].parser,
                                    readBlock: readBlock)

        var idx = 0
        while idx < layers.count {
            if layers[idx].id != primaryLayer {
                layers[idx].parser.includedRanges = layers[idx].ranges.map { $0.tsRange }
                layers[idx].tree = createTree(parser: layers[idx].parser, readBlock: readBlock)
            }
            updateInjectedLanguageLayers(textView: textView,
                                         language: layers[idx],
                                         readBlock: readBlock)

            idx += 1
        }
    }

    /// Notifies the highlighter of an edit and in exchange gets a set of indices that need to be re-highlighted.
    /// The returned `IndexSet` should include all indexes that need to be highlighted, including any inserted text.
    /// - Parameters:
    ///   - textView:The text view to use.
    ///   - range: The range of the edit.
    ///   - delta: The length of the edit, can be negative for deletions.
    ///   - completion: The function to call with an `IndexSet` containing all Indices to invalidate.
    func applyEdit(textView: HighlighterTextView,
                   range: NSRange,
                   delta: Int,
                   completion: @escaping ((IndexSet) -> Void)) {
        guard let edit = InputEdit(range: range, delta: delta, oldEndPoint: .zero) else {
            return
        }

        let readBlock = createReadBlock(textView: textView)
        var rangeSet = IndexSet()

        // Loop through all layers and apply the edit, and query for any changed byte ranges.
        // Using a while loop b/c `updateInjectedLanguageLayers` can append new layers during the loop.
        var idx = 0
        while idx < layers.count {
            let layer = layers[idx]
            // The primary layer's range is always the entire document, no need to modify.
            if layer.id != primaryLayer {
                for idx in (0..<layer.ranges.count).reversed() {
                    layer.ranges[idx].applyInputEdit(edit)
                    // Remove any empty/negative ranges
                    if layer.ranges[idx].length <= 0 {
                        layer.ranges.remove(at: idx)
                    }
                }
            }

            layer.parser.includedRanges = layer.ranges.map { $0.tsRange }
            let effectedRanges = findChangedByteRanges(textView: textView,
                                                       edit: edit,
                                                       layer: layer,
                                                       readBlock: readBlock)
            rangeSet.insert(ranges: effectedRanges)

            // Find any injected languages & update the `layers` array.
            rangeSet.formUnion(
                updateInjectedLanguageLayers(textView: textView,
                                             language: layer,
                                             readBlock: readBlock)
            )

            idx += 1
        }

        completion(rangeSet)
    }

    /// Initiates a highlight query.
    /// - Parameters:
    ///   - textView: The text view to use.
    ///   - range: The range to limit the highlights to.
    ///   - completion: Called when the query completes.
    func queryHighlightsFor(textView: HighlighterTextView,
                            range: NSRange,
                            completion: @escaping ((([HighlightRange]) -> Void))) {
        var highlights: [HighlightRange] = []
        var injectedSet = IndexSet(integersIn: range)

        for layer in layers where layer.id != primaryLayer {
            // Query injected only if a layer's ranges intersects with `range`
            for layerRange in layer.ranges
            where layerRange.location <= NSMaxRange(range) && range.location <= NSMaxRange(layerRange) {
                let location = max(layerRange.location, range.location)
                let length = min(NSMaxRange(layerRange), NSMaxRange(range)) - location
                let rangeIntersection = NSRange(location: location,
                                                length: length)
                highlights.append(
                    contentsOf: queryLayerHighlights(layer: layer,
                                                     textView: textView,
                                                     range: rangeIntersection)
                )

                injectedSet.remove(integersIn: rangeIntersection)
            }
        }

        // Query primary for any ranges that weren't used in the injected layers.
        for range in injectedSet.rangeView {
            highlights.append(contentsOf: queryLayerHighlights(layer: layers[0],
                                                               textView: textView,
                                                               range: NSRange(range)))
        }

        completion(highlights)
    }

    // MARK: - Helpers

    /// Attempts to add a language to the `languages` dictionary.
    /// - Parameter language: The language to add.
    internal func addLanguageLayer(layerId: TreeSitterLanguage, readBlock: @escaping Parser.ReadBlock) {
        let newLayer = LanguageLayer(id: layerId,
                                     parser: Parser(),
                                     tree: nil,
                                     languageQuery: TreeSitterModel.shared.query(for: layerId),
                                     ranges: [])

        guard let parserLanguage = CodeLanguage
            .allLanguages
            .first(where: { $0.id == layerId })?
            .language
        else {
            return
        }

        try? newLayer.parser.setLanguage(parserLanguage)

        layers.append(newLayer)
    }

    /// Creates a tree-sitter tree.
    /// - Parameters:
    ///   - parser: The parser object to use to parse text.
    ///   - readBlock: A callback for fetching blocks of text.
    /// - Returns: A tree if it could be parsed.
    internal func createTree(parser: Parser, readBlock: @escaping Parser.ReadBlock) -> Tree? {
        return parser.parse(tree: nil, readBlock: readBlock)
    }

    internal func createReadBlock(textView: HighlighterTextView) -> Parser.ReadBlock {
        return { byteOffset, _ in
            let limit = textView.documentRange.length
            let location = byteOffset / 2
            let end = min(location + (1024), limit)
            if location > end {
                assertionFailure("location is greater than end")
                return nil
            }
            let range = NSRange(location..<end)
            return textView.stringForRange(range)?.data(using: String.nativeUTF16Encoding)
        }
    }
}
