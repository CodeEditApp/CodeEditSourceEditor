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
final class TreeSitterClient {
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

    /// Set when the tree-sitter has text set.
    public var hasSetText: Bool = false

    /// Reparses the tree-sitter tree using the given text.
    /// - Parameter text: The text to parse.
    public func setText(text: String) {
        tree = self.parser.parse(text)
        hasSetText = true
    }

    /// Sets the language for the parser. Will cause a complete invalidation of the code, so use sparingly.
    /// - Parameters:
    ///   - codeLanguage: The code language to use.
    ///   - text: The text to use to re-parse.
    public func setLanguage(codeLanguage: CodeLanguage, text: String) throws {
        parser = Parser()
        languageQuery = TreeSitterModel.shared.query(for: codeLanguage.id)

        if let treeSitterLanguage = codeLanguage.language {
            try parser.setLanguage(treeSitterLanguage)
        }

        tree = self.parser.parse(text)
        hasSetText = true
    }

    /// Applies an edit to the code tree and calls the completion handler with any affected ranges.
    /// - Parameters:
    ///   - edit: The edit to apply.
    ///   - text: The text content with the edit applied.
    ///   - completion: Called when affected ranges are found.
    public func applyEdit(_ edit: InputEdit, text: String, completion: @escaping ((IndexSet) -> Void)) {
        let readFunction = Parser.readFunction(for: text)

        let (oldTree, newTree) = self.calculateNewState(edit: edit,
                                                        text: text,
                                                        readBlock: readFunction)

        let effectedRanges = self.changedByteRanges(oldTree, rhs: newTree).map { $0.range }

        var rangeSet = IndexSet()
        effectedRanges.forEach { range in
            rangeSet.insert(integersIn: Range(range)!)
        }
        completion(rangeSet)
    }

    /// Queries highlights for a given range. Will return on the main thread.
    /// - Parameters:
    ///   - range: The range to query
    ///   - completion: Called with any highlights found in the query.
    public func queryColorsFor(range: NSRange, completion: @escaping (([HighlightRange]) -> Void)) {
        self.semaphore.wait()
        guard let tree = self.tree?.copy() else {
            self.semaphore.signal()
            completion([])
            return
        }
        self.semaphore.signal()

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

    /// Resolves a query cursor to the highlight ranges it contains.
    /// **Must be called on the main thread**
    /// - Parameter cursor: The cursor to resolve.
    /// - Returns: Any highlight ranges contained in the cursor.
    private func highlightsFromCursor(cursor: ResolvingQueryCursor) -> [HighlightRange] {
        cursor.prepare(with: self.textProvider)
        return cursor
            .flatMap { $0.captures }
            .map { HighlightRange(range: $0.range, capture: CaptureName(rawValue: $0.name ?? "")) }
    }
}

extension TreeSitterClient {
    /// Applies the edit to the current `tree` and returns the old tree and a copy of the current tree with the
    /// processed edit.
    /// - Parameter edit: The edit to apply.
    /// - Returns: (The old state, the new state).
    private func calculateNewState(edit: InputEdit,
                                   text: String,
                                   readBlock: @escaping Parser.ReadBlock) -> (Tree?, Tree?) {
        guard let oldTree = self.tree else {
            self.tree = self.parser.parse(text)
            return (nil, self.tree)
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
