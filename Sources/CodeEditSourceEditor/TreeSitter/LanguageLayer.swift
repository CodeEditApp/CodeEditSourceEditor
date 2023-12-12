//
//  TreeSitterClient+LanguageLayer.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 3/8/23.
//

import Foundation
import CodeEditLanguages
import SwiftTreeSitter

public class LanguageLayer: Hashable {
    /// Initialize a language layer
    /// - Parameters:
    ///   - id: The ID of the layer.
    ///   - parser: A parser to use for the layer.
    ///   - supportsInjections: Set to true when the langauge supports the `injections` query.
    ///   - tree: The tree-sitter tree generated while editing/parsing a document.
    ///   - languageQuery: The language query used for fetching the associated `queries.scm` file
    ///   - ranges: All ranges this layer acts on. Must be kept in order and w/o overlap.
    init(
        id: TreeSitterLanguage,
        parser: Parser,
        supportsInjections: Bool,
        tree: Tree? = nil,
        languageQuery: Query? = nil,
        ranges: [NSRange]
    ) {
        self.id = id
        self.parser = parser
        self.supportsInjections = supportsInjections
        self.tree = tree
        self.languageQuery = languageQuery
        self.ranges = ranges

        self.parser.timeout = TreeSitterClient.Constants.parserTimeout
    }

    let id: TreeSitterLanguage
    let parser: Parser
    let supportsInjections: Bool
    var tree: Tree?
    var languageQuery: Query?
    var ranges: [NSRange]

    func copy() -> LanguageLayer {
        return LanguageLayer(
            id: id,
            parser: parser,
            supportsInjections: supportsInjections,
            tree: tree?.copy(),
            languageQuery: languageQuery,
            ranges: ranges
        )
    }

    public static func == (lhs: LanguageLayer, rhs: LanguageLayer) -> Bool {
        return lhs.id == rhs.id && lhs.ranges == rhs.ranges
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(ranges)
    }

    /// Calculates a series of ranges that have been invalidated by a given edit.
    /// - Parameters:
    ///   - textView: The text view to use for text.
    ///   - edit: The edit to act on.
    ///   - timeout: The maximum time interval the parser can run before halting.
    ///   - readBlock: A callback for fetching blocks of text.
    /// - Returns: An array of distinct `NSRanges` that need to be re-highlighted.
    func findChangedByteRanges(
        textView: HighlighterTextView,
        edit: InputEdit,
        timeout: TimeInterval?,
        readBlock: @escaping Parser.ReadBlock
    ) throws -> [NSRange] {
        parser.timeout = timeout ?? 0

        let (oldTree, newTree) = calculateNewState(
            tree: self.tree,
            parser: self.parser,
            edit: edit,
            readBlock: readBlock
        )

        if oldTree == nil && newTree == nil {
            // There was no existing tree, make a new one and return all indexes.
            tree = parser.createTree(readBlock: readBlock)
            return [NSRange(textView.documentRange.intRange)]
        } else if oldTree != nil && newTree == nil {
            // The parser timed out,
            throw Error.parserTimeout
        }

        let ranges = changedByteRanges(oldTree, rhs: newTree).map { $0.range }

        tree = newTree

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
    internal func calculateNewState(
        tree: Tree?,
        parser: Parser,
        edit: InputEdit,
        readBlock: @escaping Parser.ReadBlock
    ) -> (Tree?, Tree?) {
        guard let oldTree = tree else {
            return (nil, nil)
        }

        // Apply the edit to the old tree
        oldTree.edit(edit)

        let newTree = parser.parse(tree: oldTree, readBlock: readBlock)

        return (oldTree.copy(), newTree)
    }

    /// Calculates the changed byte ranges between two trees.
    /// - Parameters:
    ///   - lhs: The first (older) tree.
    ///   - rhs: The second (newer) tree.
    /// - Returns: Any changed ranges.
    internal func changedByteRanges(_ lhs: Tree?, rhs: Tree?) -> [Range<UInt32>] {
        switch (lhs, rhs) {
        case (let tree1?, let tree2?):
            return tree1.changedRanges(from: tree2).map({ $0.bytes })
        case (nil, let tree2?):
            let range = tree2.rootNode?.byteRange

            return range.flatMap({ [$0] }) ?? []
        case (_, nil):
            return []
        }
    }

    enum Error: Swift.Error {
        case parserTimeout
    }
}
