//
//  TreeSitterModel.swift
//  CodeEditTextView/CodeLanguage
//
//  Created by Lukas Pistrol on 25.05.22.
//

import Foundation
import SwiftTreeSitter

/// A singleton class to manage `tree-sitter` queries and keep them in memory.
///
/// This is important to not having to refetch queries any time a new file
/// is opened since this can be very expensive
public class TreeSitterModel {

    /// The singleton/shared instance of ``TreeSitterModel``.
    public static let shared: TreeSitterModel = .init()

    /// Get a query for a specific language
    /// - Parameter language: The language to request the query for.
    /// - Returns: A Query if available. Returns `nil` for not implemented languages
    public func query(for language: TreeSitterLanguage) -> Query? {
        switch language {
        case .go:
            return goQuery
        case .goMod:
            return goModQuery
        case .html:
            return htmlQuery
        case .json:
            return jsonQuery
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

    public lazy var swiftQuery: Query? = {
        return queryFor(.swift)
    }()

    public lazy var goQuery: Query? = {
        return queryFor(.go)
    }()

    public lazy var goModQuery: Query? = {
        return queryFor(.goMod)
    }()

    public lazy var htmlQuery: Query? = {
        return queryFor(.html)
    }()

    public lazy var jsonQuery: Query? = {
        return queryFor(.json)
    }()

    public lazy var rubyQuery: Query? = {
        return queryFor(.ruby)
    }()

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
