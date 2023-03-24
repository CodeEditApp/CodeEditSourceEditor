//
//  TreeSitterClient+LanguageLayer.swift
//  
//
//  Created by Khan Winter on 3/8/23.
//

import Foundation
import CodeEditLanguages
import SwiftTreeSitter

extension TreeSitterClient {
    class LanguageLayer: Hashable {
        /// Initialize a language layer
        /// - Parameters:
        ///   - id: The ID of the layer.
        ///   - parser: A parser to use for the layer.
        ///   - supportsInjections: Set to true when the langauge supports the `injections` query.
        ///   - tree: The tree-sitter tree generated while editing/parsing a document.
        ///   - languageQuery: The language query used for fetching the associated `queries.scm` file
        ///   - ranges: All ranges this layer acts on. Must be kept in order and w/o overlap.
        init(id: TreeSitterLanguage,
             parser: Parser,
             supportsInjections: Bool,
             tree: Tree? = nil,
             languageQuery: Query? = nil,
             ranges: [NSRange]) {
            self.id = id
            self.parser = parser
            self.supportsInjections = supportsInjections
            self.tree = tree
            self.languageQuery = languageQuery
            self.ranges = ranges
        }

        let id: TreeSitterLanguage
        let parser: Parser
        let supportsInjections: Bool
        var tree: Tree?
        var languageQuery: Query?
        var ranges: [NSRange]

        static func == (lhs: TreeSitterClient.LanguageLayer, rhs: TreeSitterClient.LanguageLayer) -> Bool {
            return lhs.id == rhs.id && lhs.ranges == rhs.ranges
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(ranges)
        }
    }
}
