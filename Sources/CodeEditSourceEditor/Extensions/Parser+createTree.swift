//
//  Parser+createTree.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 5/20/23.
//

import Foundation
import SwiftTreeSitter

extension Parser {
    /// Creates a tree-sitter tree.
    /// - Parameters:
    ///   - parser: The parser object to use to parse text.
    ///   - readBlock: A callback for fetching blocks of text.
    /// - Returns: A tree if it could be parsed.
    internal func createTree(readBlock: @escaping Parser.ReadBlock) -> Tree? {
        return parse(tree: nil, readBlock: readBlock)
    }
}
