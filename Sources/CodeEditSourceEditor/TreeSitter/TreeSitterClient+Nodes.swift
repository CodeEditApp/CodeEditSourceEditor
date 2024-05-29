//
//  TreeSitterClient+Nodes.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 5/27/24.
//

import Foundation
import CodeEditLanguages
import SwiftTreeSitter

// Functions for querying and navigating the tree-sitter node tree. These functions should throw if not able to be
// performed asynchronously as (currently) any editing tasks that would use these must be performed synchronously.

extension TreeSitterClient {
    /// Finds nodes for each language layer at the given location.
    /// - Parameter location: The location to get a node for.
    /// - Returns: All pairs of `Language, Node` where Node is the nearest node in the tree at the given location.
    /// - Throws: A ``TreeSitterClient.Error`` error.
    public func nodesAt(location: Int) throws -> [(Language, Node)] {
        let range = NSRange(location: location, length: 1)
        return try nodesAt(range: range)
    }

    /// Finds nodes in each language layer for the given range.
    /// - Parameter range: The range to get a node for.
    /// - Returns: All pairs of `Language, Node` where Node is the nearest node in the tree in the given range.
    /// - Throws: A ``TreeSitterClient.Error`` error.
    public func nodesAt(range: NSRange) throws -> [(Language, Node)] {
        return try performSync { [weak self] in
            var nodes: [(Language, Node)] = []
            for layer in self?.state?.layers ?? [] {
                if let language = layer.tsLanguage,
                   let node = layer.tree?.rootNode?.descendant(in: range.tsRange.bytes) {
                    nodes.append((language, node))
                }
            }
            return nodes
        }
    }
}
