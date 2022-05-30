//
//  TreeSitterModel.swift
//  CodeEditTextView/CodeLanguage
//
//  Created by Lukas Pistrol on 25.05.22.
//

import Foundation
import SwiftTreeSitter

/// A singleton class to manage `tree-sitter` queries and keep them in memory.
public class TreeSitterModel {

    /// The singleton/shared instance of ``TreeSitterModel``.
    public static let shared: TreeSitterModel = .init()

    /// Get a query for a specific language
    /// - Parameter language: The language to request the query for.
    /// - Returns: A Query if available. Returns `nil` for not implemented languages
    // swiftlint:disable:next cyclomatic_complexity
    public func query(for language: TreeSitterLanguage) -> Query? {
        switch language {
        case .css:
            return cssQuery
        case .go:
            return goQuery
        case .goMod:
            return goModQuery
        case .html:
            return htmlQuery
        case .java:
            return javaQuery
        case .json:
            return jsonQuery
        case .python:
            return pythonQuery
        case .ruby:
            return rubyQuery
        case .swift:
            return swiftQuery
        case .yaml:
            return yamlQuery
        case .plainText:
            return nil
        }
    }

    /// Query for `CSS` files.
    public lazy var cssQuery: Query? = {
        return queryFor(.css)
    }()

    /// Query for `Go` files.
    public lazy var goQuery: Query? = {
        return queryFor(.go)
    }()

    /// Query for `GoMod` files.
    public lazy var goModQuery: Query? = {
        return queryFor(.goMod)
    }()

    /// Query for `HTML` files.
    public lazy var htmlQuery: Query? = {
        return queryFor(.html)
    }()

    /// Query for `Java` files.
    public lazy var javaQuery: Query? = {
        return queryFor(.java)
    }()

    /// Query for `JSON` files.
    public lazy var jsonQuery: Query? = {
        return queryFor(.json)
    }()

    /// Query for `Python` files.
    public lazy var pythonQuery: Query? = {
        return queryFor(.python)
    }()

    /// Query for `Ruby` files.
    public lazy var rubyQuery: Query? = {
        return queryFor(.ruby)
    }()

    /// Query for `Swift` files.
    public lazy var swiftQuery: Query? = {
        return queryFor(.swift)
    }()

    /// Query for `YAML` files.
    public lazy var yamlQuery: Query? = {
        return queryFor(.yaml)
    }()

    private func queryFor(_ codeLanguage: CodeLanguage) -> Query? {
        guard let language = codeLanguage.language,
              let url = codeLanguage.queryURL else { return nil }
        return try? language.query(contentsOf: url)
    }

    private init() {}
}
