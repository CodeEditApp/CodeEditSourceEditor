//
//  TreeSitterClient+Highlight.swift
//  
//
//  Created by Khan Winter on 3/10/23.
//

import Foundation
import SwiftTreeSitter
import CodeEditLanguages

extension TreeSitterClient {

    /// Queries the given language layer for any highlights.
    /// - Parameters:
    ///   - layer: The layer to query.
    ///   - textView: A text view to use for contextual data.
    ///   - range: The range to query for.
    /// - Returns: Any ranges to highlight.
    internal func queryLayerHighlights(layer: LanguageLayer,
                                       textView: HighlighterTextView,
                                       range: NSRange) -> [HighlightRange] {
        // Make sure we don't change the tree while we copy it.
        self.semaphore.wait()

        guard let tree = layer.tree?.copy() else {
            self.semaphore.signal()
            return []
        }

        self.semaphore.signal()

        guard let rootNode = tree.rootNode else {
            return []
        }

        // This needs to be on the main thread since we're going to use the `textProvider` in
        // the `highlightsFromCursor` method, which uses the textView's text storage.
        guard let cursor = layer.languageQuery?.execute(node: rootNode, in: tree) else {
            return []
        }
        cursor.setRange(range)
        cursor.matchLimit = Constants.treeSitterMatchLimit

        return highlightsFromCursor(cursor: ResolvingQueryCursor(cursor: cursor))
    }

    /// Performs an injections query on the given language layer.
    /// Updates any existing layers with new ranges and adds new layers if needed.
    /// - Parameters:
    ///   - textView: The text view to use.
    ///   - language: The language layer to perform the query on.
    ///   - readBlock: A completion block for reading from text storage efficiently.
    /// - Returns: An index set of any updated indexes.
    @discardableResult
    internal func updateInjectedLanguageLayers(textView: HighlighterTextView,
                                               language: LanguageLayer,
                                               readBlock: @escaping Parser.ReadBlock) -> IndexSet {
        guard let tree = language.tree,
              let rootNode = tree.rootNode,
              let cursor = language.languageQuery?.execute(node: rootNode, in: tree) else {
            return IndexSet()
        }

        cursor.matchLimit = Constants.treeSitterMatchLimit

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

            if let layer = layers.first(where: { $0.id == treeSitterLanguage }) {
                // Add any ranges not included in the layer already
                for namedRange in ranges
                where !layer.ranges.contains(where: { $0.intersection(namedRange.range) != nil }) {
                    updatedRanges.insert(range: namedRange.range)
                    layer.ranges.append(namedRange.range)
                }
            } else {
                // Add the language if not available
                addLanguageLayer(layerId: treeSitterLanguage, readBlock: readBlock)

                let layerIndex = layers.count - 1
                guard layers.last?.id == treeSitterLanguage else {
                    continue
                }

                layers[layerIndex].parser.includedRanges = ranges.map { $0.tsRange }
                layers[layerIndex].ranges = ranges.map { $0.range }
                layers[layerIndex].tree = createTree(parser: layers[layerIndex].parser, readBlock: readBlock)
            }
        }
        return updatedRanges
    }

    /// Resolves a query cursor to the highlight ranges it contains.
    /// **Must be called on the main thread**
    /// - Parameter cursor: The cursor to resolve.
    /// - Returns: Any highlight ranges contained in the cursor.
    internal func highlightsFromCursor(cursor: ResolvingQueryCursor) -> [HighlightRange] {
        cursor.prepare(with: self.textProvider)
        return cursor
            .flatMap { $0.captures }
            .compactMap {
                // Some languages add an "@spell" capture to indicate a portion of text that should be spellchecked
                // (usually comments). But this causes other captures in the same range to be overriden. So we ignore
                // that specific capture type.
                if $0.name != "spell" && $0.name != "injection.content" {
                    return HighlightRange(range: $0.range, capture: CaptureName.fromString($0.name ?? ""))
                }
                return nil
            }
    }

    /// Returns all injected languages from a given cursor. The cursor must be new,
    /// having not been used for normal highlight matching.
    /// - Parameters:
    ///   - cursor: The cursor to use for finding injected languages.
    ///   - textProvider: A callback for efficiently fetching text.
    /// - Returns: A map of each language to all the ranges they have been injected into.
    internal func injectedLanguagesFrom(
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
