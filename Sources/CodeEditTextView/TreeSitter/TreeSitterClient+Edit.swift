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
                // and update any overlapping ones.
                for namedRange in ranges where namedRange.range.length > 0 {
                    var wasRangeFound = false

                    for (idx, layerRange) in layer.ranges.enumerated().reversed()
                    where namedRange.range.intersection(layerRange) != nil {
                        wasRangeFound = true
                        layer.ranges[idx] = namedRange.range
                        break
                    }

                    if !wasRangeFound {
                        layer.ranges.append(namedRange.range)
                        updatedRanges.insert(range: namedRange.range)
                    }
                }

                // Required for tree-sitter to work. Assumes no ranges are overlapping.
                layer.ranges.sort()
            } else {
                // Add the language if not available
                addLanguageLayer(layerId: treeSitterLanguage, readBlock: readBlock)

                let layerIndex = layers.count - 1
                guard layers.last?.id == treeSitterLanguage else {
                    continue
                }

                layers[layerIndex].parser.includedRanges = ranges
                    .filter { $0.range.length > 0 }
                    .map { $0.tsRange }
                    .sorted()
                layers[layerIndex].ranges = ranges.filter { $0.range.length > 0 }.map { $0.range }
                layers[layerIndex].tree = createTree(parser: layers[layerIndex].parser, readBlock: readBlock)
            }
        }
        return updatedRanges
    }
}
