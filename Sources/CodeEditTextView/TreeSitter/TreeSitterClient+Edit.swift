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
}
