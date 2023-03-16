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
