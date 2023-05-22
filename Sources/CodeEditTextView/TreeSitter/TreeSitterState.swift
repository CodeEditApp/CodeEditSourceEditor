//
//  TreeSitterState.swift
//  CodeEditTextView
//
//  Created by Khan Winter on 5/21/23.
//

import Foundation
import SwiftTreeSitter
import CodeEditLanguages

/// TreeSitterState contains the tree of language layers that make up the tree-sitter document.
/// Use the given 
class TreeSitterState {
    private(set) var primaryLayer: TreeSitterLanguage
    private(set) var layers: [TSLanguageLayer] = []

    // MARK: - Init

    init(primaryLayer: TreeSitterLanguage) {
        self.primaryLayer = primaryLayer
    }

    /// Initialize the state object with the given read block.
    /// - Parameter textView: The textView to use as a data source.
    public func setUp(textView: HighlighterTextView) {
        let readBlock = textView.createReadBlock()

        let previousTimeout = layers[0].parser.timeout
        layers[0].parser.timeout = 0.0
        layers[0].tree = layers[0].parser.createTree(readBlock: readBlock)
        layers[0].parser.timeout = previousTimeout

        var layerSet = Set<TSLanguageLayer>(arrayLiteral: layers[0])
        var touchedLayers = Set<TSLanguageLayer>()

        var idx = 0
        while idx < layers.count {
            updateInjectedLanguageLayer(
                textView: textView,
                layer: layers[idx],
                layerSet: &layerSet,
                touchedLayers: &touchedLayers
            )

            idx += 1
        }
    }

    /// Sets the primary language for the client. Will reset all layers, will not do any parsing work.
    /// - Parameter codeLanguage: The new primary language.
    public func setLanguage(codeLanguage: CodeLanguage) {
        // Remove all trees and languages, everything needs to be re-parsed.
        layers.removeAll()

        primaryLayer = codeLanguage.id
        layers = [
            TSLanguageLayer(
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

    // MARK: - Layer Management

    /// Removes a layer at the given index.
    /// - Parameter idx: The index of the layer to remove.
    public func removeLanguageLayer(at idx: Int) {
        layers.remove(at: idx)
    }

    public func removeLanguageLayers(in set: Set<TSLanguageLayer>) {
        layers.removeAll(where: { set.contains($0 )})
    }

    /// Attempts to create a language layer and load a highlights file.
    /// Adds the layer to the `layers` array if successful.
    /// - Parameters:
    ///   - layerId: A language ID to add as a layer.
    ///   - readBlock: Completion called for efficient string lookup.
    public func addLanguageLayer(
        layerId: TreeSitterLanguage,
        readBlock: @escaping Parser.ReadBlock
    ) -> TSLanguageLayer? {
        guard let language = CodeLanguage.allLanguages.first(where: { $0.id == layerId }),
              let parserLanguage = language.language
        else {
            return nil
        }

        let newLayer = TSLanguageLayer(
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

    // MARK: - Injection Layers

    /// Inserts any new language layers, and removes any that may have been deleted after an edit.
    /// - Parameters:
    ///   - textView: The data source for text ranges.
    ///   - touchedLayers: A set of layers. Each time a layer is visited, it will be removed from this set.
    ///                    Use this to determine if any layers were not modified after this method was run.
    ///                    Those layers should be removed.
    /// - Returns: A set of indices of any new layers. This set indicates ranges that should be re-highlighted.
    public func updateInjectedLayers(
        textView: HighlighterTextView,
        touchedLayers: Set<TSLanguageLayer>
    ) -> IndexSet {
        var layerSet = Set(layers)
        var touchedLayers = touchedLayers
        var rangeSet = IndexSet()

        // Loop through each layer and apply injections query, add any ranges not previously found
        // using while loop because `updateInjectedLanguageLayer` can add to `layers` during the loop
        var idx = 0
        while idx < layers.count {
            let layer = layers[idx]

            if layer.supportsInjections {
                rangeSet.formUnion(
                    updateInjectedLanguageLayer(
                        textView: textView,
                        layer: layer,
                        layerSet: &layerSet,
                        touchedLayers: &touchedLayers
                    )
                )
            }

            idx += 1
        }

        // Delete any layers that weren't touched at some point during the edit.
        removeLanguageLayers(in: touchedLayers)

        return rangeSet
    }

    /// Performs an injections query on the given language layer.
    /// Updates any existing layers with new ranges and adds new layers if needed.
    /// - Parameters:
    ///   - textView: The text view to use.
    ///   - layer: The language layer to perform the query on.
    ///   - layerSet: The set of layers that exist in the document.
    ///               Used for efficient lookup of existing `(language, range)` pairs
    ///   - touchedLayers: The set of layers that existed before updating injected layers.
    ///                    Will have items removed as they are found.
    /// - Returns: An index set of any updated indexes.
    @discardableResult
    private func updateInjectedLanguageLayer(
        textView: HighlighterTextView,
        layer: TSLanguageLayer,
        layerSet: inout Set<TSLanguageLayer>,
        touchedLayers: inout Set<TSLanguageLayer>
    ) -> IndexSet {
        guard let tree = layer.tree,
              let rootNode = tree.rootNode,
              let cursor = layer.languageQuery?.execute(node: rootNode, in: tree) else {
            return IndexSet()
        }

        cursor.matchLimit = TreeSitterClient.Constants.treeSitterMatchLimit

        let languageRanges = self.injectedLanguagesFrom(cursor: cursor) { range, _ in
            return textView.stringForRange(range)
        }

        var updatedRanges = IndexSet()

        for (languageName, ranges) in languageRanges {
            guard let treeSitterLanguage = TreeSitterLanguage(rawValue: languageName) else {
                continue
            }

            if treeSitterLanguage == primaryLayer {
                continue
            }

            for range in ranges {
                // Temp layer object
                let layer = TSLanguageLayer(
                    id: treeSitterLanguage,
                    parser: Parser(),
                    supportsInjections: false,
                    ranges: [range.range]
                )

                if layerSet.contains(layer) {
                    // If we've found this layer, it means it should exist after an edit.
                    touchedLayers.remove(layer)
                } else {
                    let readBlock = textView.createReadBlock()
                    // New range, make a new layer!
                    if let addedLayer = addLanguageLayer(layerId: treeSitterLanguage, readBlock: readBlock) {
                        addedLayer.ranges = [range.range]
                        addedLayer.parser.includedRanges = addedLayer.ranges.map { $0.tsRange }
                        addedLayer.tree = addedLayer.parser.createTree(readBlock: readBlock)

                        layerSet.insert(addedLayer)
                        updatedRanges.insert(range: range.range)
                    }
                }
            }
        }

        return updatedRanges
    }

    /// Returns all injected languages from a given cursor. The cursor must be new,
    /// having not been used for normal highlight matching.
    /// - Parameters:
    ///   - cursor: The cursor to use for finding injected languages.
    ///   - textProvider: A callback for efficiently fetching text.
    /// - Returns: A map of each language to all the ranges they have been injected into.
    private func injectedLanguagesFrom(
        cursor: QueryCursor,
        textProvider: @escaping ResolvingQueryCursor.TextProvider
    ) -> [String: [NamedRange]] {
        var languages: [String: [NamedRange]] = [:]

        for match in cursor {
            if let injection = match.injection(with: textProvider) {
                if languages[injection.name] == nil {
                    languages[injection.name] = []
                }
                languages[injection.name]?.append(injection)
            }
        }

        return languages
    }
}
