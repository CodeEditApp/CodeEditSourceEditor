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
    public init(codeLanguage: CodeLanguage, textProvider: @escaping ResolvingQueryCursor.TextProvider) {
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
            LanguageLayer(
                id: codeLanguage.id,
                parser: Parser(),
                supportsInjections: codeLanguage.additionalHighlights?.contains("injections") ?? false,
                tree: nil,
                languageQuery: TreeSitterModel.shared.query(for: codeLanguage.id),
                ranges: []
            )
        ]

        if let treeSitterLanguage = codeLanguage.language {
            try? layers[0].parser.setLanguage(treeSitterLanguage)
        }
    }

    // MARK: - HighlightProviding

    /// Set up and parse the initial language tree and all injected layers.
    func setUp(textView: HighlighterTextView) {
        let readBlock = createReadBlock(textView: textView)

        layers[0].tree = createTree(
            parser: layers[0].parser,
            readBlock: readBlock
        )

        var layerSet = Set<LanguageLayer>(arrayLiteral: layers[0])
        var touchedLayers = Set<LanguageLayer>()

        var idx = 0
        while idx < layers.count {
            updateInjectedLanguageLayers(
                textView: textView,
                layer: layers[idx],
                layerSet: &layerSet,
                touchedLayers: &touchedLayers,
                readBlock: readBlock
            )

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
    func applyEdit(
        textView: HighlighterTextView,
        range: NSRange,
        delta: Int,
        completion: @escaping ((IndexSet) -> Void)
    ) {
        guard let edit = InputEdit(range: range, delta: delta, oldEndPoint: .zero) else { return }
        let readBlock = createReadBlock(textView: textView)
        var rangeSet = IndexSet()

        // Helper data structure for finding existing layers in O(1) when adding injected layers
        var layerSet = Set<LanguageLayer>(minimumCapacity: layers.count)
        // Tracks which layers were not touched at some point during the edit. Any layers left in this set
        // after the second loop are removed.
        var touchedLayers = Set<LanguageLayer>(minimumCapacity: layers.count)

        // Loop through all layers, apply edits & find changed byte ranges.
        for layerIdx in (0..<layers.count).reversed() {
            let layer = layers[layerIdx]

            if layer.id != primaryLayer {
                // Reversed for safe removal while looping
                for rangeIdx in (0..<layer.ranges.count).reversed() {
                    layer.ranges[rangeIdx].applyInputEdit(edit)

                    if layer.ranges[rangeIdx].length <= 0 {
                        layer.ranges.remove(at: rangeIdx)
                    }
                }
                if layer.ranges.isEmpty {
                    layers.remove(at: layerIdx)
                    continue
                }

                touchedLayers.insert(layer)
            }

            layer.parser.includedRanges = layer.ranges.map { $0.tsRange }
            rangeSet.insert(
                ranges: findChangedByteRanges(
                    textView: textView,
                    edit: edit,
                    layer: layer,
                    readBlock: readBlock
                )
            )

            layerSet.insert(layer)
        }

        // Loop again and apply injections query, add any ranges not previously found
        // using while loop because `updateInjectedLanguageLayers` can add to `layers` during the loop
        var idx = 0
        while idx < layers.count {
            let layer = layers[idx]

            if layer.supportsInjections {
                rangeSet.formUnion(
                    updateInjectedLanguageLayers(
                        textView: textView,
                        layer: layer,
                        layerSet: &layerSet,
                        touchedLayers: &touchedLayers,
                        readBlock: readBlock
                    )
                )
            }

            idx += 1
        }

        // Delete any layers that weren't touched at some point during the edit.
        layers.removeAll(where: { touchedLayers.contains($0) })

        completion(rangeSet)
    }

    /// Initiates a highlight query.
    /// - Parameters:
    ///   - textView: The text view to use.
    ///   - range: The range to limit the highlights to.
    ///   - completion: Called when the query completes.
    func queryHighlightsFor(
        textView: HighlighterTextView,
        range: NSRange,
        completion: @escaping ((([HighlightRange]) -> Void))
    ) {
        var highlights: [HighlightRange] = []
        var injectedSet = IndexSet(integersIn: range)

        for layer in layers where layer.id != primaryLayer {
            // Query injected only if a layer's ranges intersects with `range`
            for layerRange in layer.ranges {
                if let rangeIntersection = range.intersection(layerRange) {
                    highlights.append(contentsOf: queryLayerHighlights(
                        layer: layer,
                        textView: textView,
                        range: rangeIntersection
                    ))

                    injectedSet.remove(integersIn: rangeIntersection)
                }
            }
        }

        // Query primary for any ranges that weren't used in the injected layers.
        for range in injectedSet.rangeView {
            highlights.append(contentsOf: queryLayerHighlights(
                layer: layers[0],
                textView: textView,
                range: NSRange(range)
            ))
        }

        completion(highlights)
    }

    // MARK: - Helpers

    /// Attempts to create a language layer and load a highlights file.
    /// Adds the layer to the `layers` array if successful.
    /// - Parameters:
    ///   - layerId: A language ID to add as a layer.
    ///   - readBlock: Completion called for efficient string lookup.
    internal func addLanguageLayer(
        layerId: TreeSitterLanguage,
        readBlock: @escaping Parser.ReadBlock
    ) -> LanguageLayer? {
        guard let language = CodeLanguage.allLanguages.first(where: { $0.id == layerId }),
              let parserLanguage = language.language
        else {
            return nil
        }

        let newLayer = LanguageLayer(
            id: layerId,
            parser: Parser(),
            supportsInjections: language.additionalHighlights?.contains("injections") ?? false,
            tree: nil,
            languageQuery: TreeSitterModel.shared.query(for: layerId),
            ranges: []
        )

        do {
            try newLayer.parser.setLanguage(parserLanguage)
        } catch {
            return nil
        }

        layers.append(newLayer)
        return newLayer
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
                // Ignore and return nothing, tree-sitter's internal tree can be incorrect in some situations.
                return nil
            }
            let range = NSRange(location..<end)
            return textView.stringForRange(range)?.data(using: String.nativeUTF16Encoding)
        }
    }
}
