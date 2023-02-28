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

    private var primaryLanguage: TreeSitterLanguage
    private var languages: [TreeSitterLanguage: Language] = [:]

    class Language {
        init(id: TreeSitterLanguage,
             parser: Parser,
             tree: Tree? = nil,
             languageQuery: Query? = nil) {
            self.id = id
            self.parser = parser
            self.tree = tree
            self.languageQuery = languageQuery
        }

        var id: TreeSitterLanguage
        var parser: Parser
        var tree: Tree?
        var languageQuery: Query?
    }

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
        primaryLanguage = codeLanguage.id
        languages[codeLanguage.id] = Language(id: codeLanguage.id,
                                              parser: Parser(),
                                              tree: nil,
                                              languageQuery: TreeSitterModel.shared.query(for: codeLanguage.id))

        self.textProvider = textProvider

        if let treeSitterLanguage = codeLanguage.language {
            try languages[codeLanguage.id]?.parser.setLanguage(treeSitterLanguage)
        }
    }

    func setLanguage(codeLanguage: CodeLanguage) {
        // Remove all trees and languages, everything needs to be re-parsed.
        for key in languages.keys where key != codeLanguage.id {
            languages.removeValue(forKey: key)
        }
        primaryLanguage = codeLanguage.id

        if let treeSitterLanguage = codeLanguage.language {
            try? languages[codeLanguage.id]?.parser.setLanguage(treeSitterLanguage)
        }
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

        let effectedRanges: [NSRange] = findChangedByteRanges(
            textView: textView,
            edit: edit,
            language: languages[primaryLanguage]!,
            readBlock: readFunction
        )

        var rangeSet = IndexSet()
        effectedRanges.forEach { range in
            rangeSet.insert(integersIn: Range(range)!)
        }
        completion(rangeSet)
    }

    /// Calculates a series of ranges that have been invalidated by a given edit.
    /// - Parameters:
    ///   - textView: The text view to use for text.
    ///   - edit: The edit to act on.
    ///   - language: The language to use.
    ///   - readBlock: A callback for fetching blocks of text.
    /// - Returns: An array of distinct `NSRanges` that need to be re-highlighted.
    func findChangedByteRanges(textView: HighlighterTextView,
                               edit: InputEdit,
                               language: Language,
                               readBlock: @escaping Parser.ReadBlock) -> [NSRange] {
        let (oldTree, newTree) = calculateNewState(tree: language.tree,
                                                   parser: language.parser,
                                                   edit: edit,
                                                   readBlock: readBlock)
        if oldTree == nil && newTree == nil {
            // There was no existing tree, make a new one and return all indexes.
            languages[language.id]?.tree = createTree(textView: textView, parser: language.parser)
            return [NSRange(textView.documentRange.intRange)]
        }

        let ranges = changedByteRanges(oldTree, rhs: newTree).map { $0.range }

        languages[language.id]?.tree = newTree

        return ranges
    }

    /// Initiates a highlight query.
    /// - Parameters:
    ///   - textView: The text view to use.
    ///   - range: The range to limit the highlights to.
    ///   - completion: Called when the query completes.
    func queryHighlightsFor(textView: HighlighterTextView,
                            range: NSRange,
                            completion: @escaping (([HighlightRange]) -> Void)) {
        let language = languages[primaryLanguage]!
        // Make sure we dont accidentally change the tree while we copy it.
        self.semaphore.wait()
        guard let tree = language.tree?.copy() else {
            // In this case, we don't have a tree to work with already, so we need to make it and try to
            // return some highlights
            language.tree = createTree(textView: textView, parser: language.parser)

            // This is slightly redundant but we're only doing one check.
            guard let treeRetry = language.tree?.copy() else {
                // Now we can return nothing for real.
                self.semaphore.signal()
                completion([])
                return
            }
            self.semaphore.signal()

            completion(
                _queryColorsFor(textView: textView, language: language, tree: treeRetry, range: range) +
                queryInjectedLanguages(textView: textView, language: language, tree: treeRetry, range: range)
            )
            return
        }

        self.semaphore.signal()

        completion(
            _queryColorsFor(textView: textView, language: language, tree: tree, range: range) +
            queryInjectedLanguages(textView: textView, language: language, tree: tree, range: range)
        )
    }

    private func _queryColorsFor(textView: HighlighterTextView,
                                 language: Language,
                                 tree: Tree,
                                 range: NSRange) -> [HighlightRange] {
        guard let rootNode = tree.rootNode else {
            return []
        }

        // This needs to be on the main thread since we're going to use the `textProvider` in
        // the `highlightsFromCursor` method, which uses the textView's text storage.
        guard let cursor = language.languageQuery?.execute(node: rootNode, in: tree) else {
            return []
        }
        cursor.setRange(range)

        let highlights = highlightsFromCursor(cursor: ResolvingQueryCursor(cursor: cursor))

        return highlights
    }

    private func queryInjectedLanguages(textView: HighlighterTextView,
                                        language: Language,
                                        tree: Tree,
                                        range: NSRange) -> [HighlightRange] {
        guard let rootNode = tree.rootNode else {
            return []
        }

        guard let cursor = language.languageQuery?.execute(node: rootNode, in: tree) else {
            return []
        }
        cursor.setRange(range)

        let languageRanges = self.injectedLanguagesFrom(cursor: cursor) { range, _ in
            return textView.stringForRange(range)
        }
        
        var highlights: [HighlightRange] = []

        for (languageName, ranges) in languageRanges {
            guard let language = TreeSitterLanguage(rawValue: languageName) else {
                continue
            }

            if language == primaryLanguage {
                continue
            }

            languages[language] = Language(id: language,
                                           parser: Parser(),
                                           tree: nil,
                                           languageQuery: TreeSitterModel.shared.query(for: language))

            guard let parserLanguage = CodeLanguage
                .allLanguages
                .first(where: { $0.id == language })?
                .language
            else {
                continue
            }
            try? languages[language]?.parser.setLanguage(parserLanguage)
            languages[language]?.parser.includedRanges = ranges.map { $0.tsRange }
            languages[language]?.tree = createTree(textView: textView, parser: languages[language]!.parser)

            for range in ranges {
                highlights.append(
                    contentsOf: _queryColorsFor(textView: textView,
                                                language: languages[language]!,
                                                tree: languages[language]!.tree!,
                                                range: range.range)
                )
            }

            highlights.append(
                contentsOf: queryInjectedLanguages(textView: textView,
                                                   language: languages[language]!,
                                                   tree: languages[language]!.tree!,
                                                   range: range)
            )
        }

        return highlights
    }

    /// Creates a tree.
    /// - Parameter textView: The text provider to use.
    private func createTree(textView: HighlighterTextView, parser: Parser) -> Tree? {
        return parser.parse(textView.stringForRange(textView.documentRange) ?? "")
    }

    /// Resolves a query cursor to the highlight ranges it contains.
    /// **Must be called on the main thread**
    /// - Parameter cursor: The cursor to resolve.
    /// - Returns: Any highlight ranges contained in the cursor.
    private func highlightsFromCursor(cursor: ResolvingQueryCursor) -> [HighlightRange] {
        cursor.prepare(with: self.textProvider)
        return cursor
            .flatMap { $0.captures }
            .map {
                HighlightRange(range: $0.range, capture: CaptureName.fromString($0.name ?? ""))
            }
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

extension TreeSitterClient {
    /// Applies the edit to the current `tree` and returns the old tree and a copy of the current tree with the
    /// processed edit.
    /// - Parameters:
    ///   - edit: The edit to apply.
    ///   - readBlock: The block to use to read text.
    /// - Returns: (The old state, the new state).
    private func calculateNewState(tree: Tree?,
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
