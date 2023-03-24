//
//  TreeSitterClient+Edit.swift
//  
//
//  Created by Khan Winter on 3/10/23.
//

import Foundation
import SwiftTreeSitter
import CodeEditLanguages

extension TreeSitterClient {

    /// Calculates a series of ranges that have been invalidated by a given edit.
    /// - Parameters:
    ///   - textView: The text view to use for text.
    ///   - edit: The edit to act on.
    ///   - language: The language to use.
    ///   - readBlock: A callback for fetching blocks of text.
    /// - Returns: An array of distinct `NSRanges` that need to be re-highlighted.
    func findChangedByteRanges(textView: HighlighterTextView,
                               edit: InputEdit,
                               layer: LanguageLayer,
                               readBlock: @escaping Parser.ReadBlock) -> [NSRange] {
        let (oldTree, newTree) = calculateNewState(tree: layer.tree,
                                                   parser: layer.parser,
                                                   edit: edit,
                                                   readBlock: readBlock)
        if oldTree == nil && newTree == nil {
            // There was no existing tree, make a new one and return all indexes.
            layer.tree = createTree(parser: layer.parser, readBlock: readBlock)
            return [NSRange(textView.documentRange.intRange)]
        }

        let ranges = changedByteRanges(oldTree, rhs: newTree).map { $0.range }

        layer.tree = newTree

        return ranges
    }

    /// Applies the edit to the current `tree` and returns the old tree and a copy of the current tree with the
    /// processed edit.
    /// - Parameters:
    ///   - tree: The tree before an edit used to parse the new tree.
    ///   - parser: The parser used to parse the new tree.
    ///   - edit: The edit to apply.
    ///   - readBlock: The block to use to read text.
    /// - Returns: (The old state, the new state).
    internal func calculateNewState(tree: Tree?,
                                    parser: Parser,
                                    edit: InputEdit,
                                    readBlock: @escaping Parser.ReadBlock) -> (Tree?, Tree?) {
        guard let oldTree = tree else {
            return (nil, nil)
        }
        semaphore.wait()

        // Apply the edit to the old tree
        oldTree.edit(edit)

        let newTree = parser.parse(tree: oldTree, readBlock: readBlock)

        semaphore.signal()

        return (oldTree.copy(), newTree)
    }

    /// Calculates the changed byte ranges between two trees.
    /// - Parameters:
    ///   - lhs: The first (older) tree.
    ///   - rhs: The second (newer) tree.
    /// - Returns: Any changed ranges.
    internal func changedByteRanges(_ lhs: Tree?, rhs: Tree?) -> [Range<UInt32>] {
        switch (lhs, rhs) {
        case (let t1?, let t2?):
            return t1.changedRanges(from: t2).map({ $0.bytes })
        case (nil, let t2?):
            let range = t2.rootNode?.byteRange

            return range.flatMap({ [$0] }) ?? []
        case (_, nil):
            return []
        }
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
    ///   - readBlock: A completion block for reading from text storage efficiently.
    /// - Returns: An index set of any updated indexes.
    @discardableResult
    internal func updateInjectedLanguageLayers(textView: HighlighterTextView,
                                               layer: LanguageLayer,
                                               layerSet: inout Set<LanguageLayer>,
                                               touchedLayers: inout Set<LanguageLayer>,
                                               readBlock: @escaping Parser.ReadBlock) -> IndexSet {
        guard let tree = layer.tree,
              let rootNode = tree.rootNode,
              let cursor = layer.languageQuery?.execute(node: rootNode, in: tree) else {
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

            for range in ranges {
                // Temp layer object for
                let layer = LanguageLayer(id: treeSitterLanguage,
                                          parser: Parser(),
                                          supportsInjections: false,
                                          ranges: [range.range])

                if layerSet.contains(layer) {
                    // If we've found this layer, it means it should exist after an edit.
                    touchedLayers.remove(layer)
                } else {
                    // New range, make a new layer!
                    if let addedLayer = addLanguageLayer(layerId: treeSitterLanguage, readBlock: readBlock) {
                        addedLayer.ranges = [range.range]
                        addedLayer.parser.includedRanges = addedLayer.ranges.map { $0.tsRange }
                        addedLayer.tree = createTree(parser: addedLayer.parser, readBlock: readBlock)

                        layerSet.insert(addedLayer)
                        updatedRanges.insert(range: range.range)
                    }
                }
            }
        }

        return updatedRanges
    }
}
