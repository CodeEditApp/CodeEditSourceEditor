//
//  CodeLanguage.swift
//  CodeEditTextView/CodeLanguage
//
//  Created by Lukas Pistrol on 25.05.22.
//

import Foundation
import tree_sitter
import SwiftTreeSitter

import TreeSitterSwift
import TreeSitterGo
import TreeSitterGoMod
import TreeSitterHTML
import TreeSitterJSON
import TreeSitterRuby
import TreeSitterYAML

/// A structure holding metadata for code languages
public struct CodeLanguage {
    /// The ID of the ``CodeLanguage``
    public let id: TreeSitterLanguage

    /// The display name of the ``CodeLanguage``
    public let displayName: String

    /// A set of file extensions for the ``CodeLanguage``
    public let extensions: Set<String>

    /// The query URL for the ``CodeLanguage`` if available
    public var queryURL: URL? {
        Bundle.main.resourceURL?
            .appendingPathComponent(bundle)
            .appendingPathComponent(highlights)
    }

    private var bundle: String {
        "TreeSitter\(displayName)_TreeSitter\(displayName).bundle"
    }
    
    private var highlights: String {
        "Contents/Resources/queries/highlights.scm"
    }

    /// The tree-sitter language for the ``CodeLanguage`` if available
    public var language: Language? {
        guard let ts_language = ts_language else { return nil }
        return Language(language: ts_language)
    }

    private var ts_language: UnsafeMutablePointer<TSLanguage>? {
        switch id {
        case .go:
            return tree_sitter_go()
        case .goMod:
            return tree_sitter_gomod()
        case .html:
            return tree_sitter_html()
        case .json:
            return tree_sitter_json()
        case .ruby:
            return tree_sitter_ruby()
        case .swift:
            return tree_sitter_swift()
        case .yaml:
            return tree_sitter_yaml()
        case .plainText:
            return nil
        }
    }

    /// Gets the corresponding ``CodeLanguage`` for the given file URL
    ///
    /// Uses the `pathExtension` URL component to detect the ``CodeLanguage``
    /// - Parameter url: The URL to get the ``CodeLanguage`` for.
    /// - Returns: A ``CodeLanguage`` structure
    public static func detectLanguageFrom(url: URL) -> CodeLanguage {
        let fileExtension = url.pathExtension.lowercased()
        let fileName = url.pathComponents.last?.lowercased()
        // This is to handle special file types without an extension (e.g., Makefile, Dockerfile)
        let fileNameOrExtension = fileExtension.isEmpty ? (fileName != nil ? fileName! : "") : fileExtension
        if let lang = knownLanguages.first(where: { lang in lang.extensions.contains(fileNameOrExtension)}) {
            return lang
        } else {
            return .default
        }
    }

    /// The default ``CodeLanguage`` (plain text)
    public static let `default` = CodeLanguage(
        id: .plainText,
        displayName: "Plain Text",
        extensions: ["txt"]
    )
}

public extension CodeLanguage {

    /// A collection of available ``CodeLanguage`` structures.
    static let knownLanguages: [CodeLanguage] = [
        .go,
        .goMod,
        .html,
        .json,
        .ruby,
        .swift,
        .yaml
    ]

    /// A ``CodeLanguage`` structure for `Go`
    static let go: CodeLanguage = .init(id: .go, displayName: "Go", extensions: ["go"])

    /// A ``CodeLanguage`` structure for `GoMod`
    static let goMod: CodeLanguage = .init(id: .goMod, displayName: "GoMod", extensions: ["mod"])

    /// A ``CodeLanguage`` structure for `HTML`
    static let html: CodeLanguage = .init(id: .html, displayName: "HTML", extensions: ["html", "htm"])

    /// A ``CodeLanguage`` structure for `JSON`
    static let json: CodeLanguage = .init(id: .json, displayName: "JSON", extensions: ["json"])

    /// A ``CodeLanguage`` structure for `Ruby`
    static let ruby: CodeLanguage = .init(id: .ruby, displayName: "Ruby", extensions: ["rb"])

    /// A ``CodeLanguage`` structure for `Swift`
    static let swift: CodeLanguage = .init(id: .swift, displayName: "Swift", extensions: ["swift"])
    
    /// A ``CodeLanguage`` structure for `YAML`
    static let yaml: CodeLanguage = .init(id: .yaml, displayName: "YAML", extensions: ["yml", "yaml"])
}
