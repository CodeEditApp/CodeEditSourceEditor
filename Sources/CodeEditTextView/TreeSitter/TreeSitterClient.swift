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

    public var identifier: String {
        "CodeEdit.TreeSitterClient"
    }

    internal var parser: Parser
    internal var tree: Tree?
    internal var languageQuery: Query?

    private var textProvider: ResolvingQueryCursor.TextProvider

    /// The queue to do  tree-sitter work on for large edits/queries
    private let queue: DispatchQueue = DispatchQueue(label: "CodeEdit.CodeEditTextView.TreeSitter",
                                                     qos: .userInteractive)

    /// Used to ensure safe use of the shared tree-sitter tree state in different sync/async contexts.
    private let semaphore: DispatchSemaphore = DispatchSemaphore(value: 1)

    /// Initializes the `TreeSitterClient` with the given parameters.
    /// - Parameters:
    ///   - codeLanguage: The language to set up the parser with.
    ///   - textProvider: The text provider callback to read any text.
    public init(codeLanguage: CodeLanguage, textProvider: @escaping ResolvingQueryCursor.TextProvider) throws {
        parser = Parser()
        languageQuery = TreeSitterModel.shared.query(for: codeLanguage.id)
        tree = nil

        self.textProvider = textProvider

        if let treeSitterLanguage = codeLanguage.language {
            try parser.setLanguage(treeSitterLanguage)
        }
    }

    func setLanguage(codeLanguage: CodeLanguage) {
        if let treeSitterLanguage = codeLanguage.language {
            try? parser.setLanguage(treeSitterLanguage)
        }

        // Get rid of the current tree, it needs to be re-parsed.
        tree = nil
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

        let readFunction: Parser.ReadBlock = { byteOffset, _ in
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

        let (oldTree, newTree) = self.calculateNewState(edit: edit,
                                                        readBlock: readFunction)

        if oldTree == nil && newTree == nil {
            // There was no existing tree, make a new one and return all indexes.
            createTree(textView: textView)
            completion(IndexSet(integersIn: textView.documentRange.intRange))
            return
        }

        let effectedRanges = self.changedByteRanges(oldTree, rhs: newTree).map { $0.range }

        var rangeSet = IndexSet()
        effectedRanges.forEach { range in
            rangeSet.insert(integersIn: Range(range)!)
        }
        completion(rangeSet)
    }

    func queryHighlightsFor(textView: HighlighterTextView,
                            range: NSRange,
                            completion: @escaping (([HighlightRange]) -> Void)) {
        // Make sure we dont accidentally change the tree while we copy it.
        self.semaphore.wait()
        guard let tree = self.tree?.copy() else {
            // In this case, we don't have a tree to work with already, so we need to make it and try to
            // return some highlights
            createTree(textView: textView)

            // This is slightly redundant but we're only doing one check.
            guard let treeRetry = self.tree?.copy() else {
                // Now we can return nothing for real.
                self.semaphore.signal()
                completion([])
                return
            }
            self.semaphore.signal()

            _queryColorsFor(tree: treeRetry, range: range, completion: completion)
            return
        }

        self.semaphore.signal()

        _queryColorsFor(tree: tree, range: range, completion: completion)
    }

    private func _queryColorsFor(tree: Tree,
                                 range: NSRange,
                                 completion: @escaping (([HighlightRange]) -> Void)) {
        guard let rootNode = tree.rootNode else {
            completion([])
            return
        }

        // This needs to be on the main thread since we're going to use the `textProvider` in
        // the `highlightsFromCursor` method, which uses the textView's text storage.
        guard let cursor = self.languageQuery?.execute(node: rootNode, in: tree) else {
            completion([])
            return
        }
        cursor.setRange(range)

        let highlights = self.highlightsFromCursor(cursor: ResolvingQueryCursor(cursor: cursor))

        completion(highlights)
    }

    /// Creates a tree.
    /// - Parameter textView: The text provider to use.
    private func createTree(textView: HighlighterTextView) {
        self.tree = self.parser.parse(textView.stringForRange(textView.documentRange) ?? "")
    }

    /// Resolves a query cursor to the highlight ranges it contains.
    /// **Must be called on the main thread**
    /// - Parameter cursor: The cursor to resolve.
    /// - Returns: Any highlight ranges contained in the cursor.
    private func highlightsFromCursor(cursor: ResolvingQueryCursor) -> [HighlightRange] {
        cursor.prepare(with: self.textProvider)
        return cursor
            .flatMap { $0.captures }
            .map { HighlightRange(range: $0.range, capture: CaptureName.fromString($0.name ?? "")) }
    }
}

extension TreeSitterClient {
    /// Applies the edit to the current `tree` and returns the old tree and a copy of the current tree with the
    /// processed edit.
    /// - Parameters:
    ///   - edit: The edit to apply.
    ///   - readBlock:  The block to use to read text.
    /// - Returns: (The old state, the new state).
    private func calculateNewState(edit: InputEdit,
                                   readBlock: @escaping Parser.ReadBlock) -> (Tree?, Tree?) {
        guard let oldTree = self.tree else {
            return (nil, nil)
        }
        self.semaphore.wait()
        
        // Apply the edit to the old tree
        oldTree.edit(edit)

        self.tree = self.parser.parse(tree: oldTree, readBlock: readBlock)

        self.semaphore.signal()

        return (oldTree.copy(), self.tree?.copy())
    }

    /// Calculates the changed byte ranges between two trees.
    /// - Parameters:
    ///   - lhs: The first (older) tree.
    ///   - rhs: The second (newer) tree.
    /// - Returns: Any changed ranges.
    private func changedByteRanges(_ lhs: Tree?, rhs: Tree?) -> [Range<UInt32>] {
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
