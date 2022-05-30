//
//  CodeLanguage.swift
//  CodeEditTextView/CodeLanguage
//
//  Created by Lukas Pistrol on 25.05.22.
//

import Foundation
import tree_sitter
import SwiftTreeSitter

import TreeSitterC
import TreeSitterCSS
import TreeSitterGo
import TreeSitterGoMod
import TreeSitterHTML
import TreeSitterJava
import TreeSitterJSON
import TreeSitterPython
import TreeSitterRuby
import TreeSitterRust
import TreeSitterSwift
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
        case .c:
            return tree_sitter_c()
        case .css:
            return tree_sitter_css()
        case .go:
            return tree_sitter_go()
        case .goMod:
            return tree_sitter_gomod()
        case .html:
            return tree_sitter_html()
        case .java:
            return tree_sitter_java()
        case .json:
            return tree_sitter_json()
        case .python:
            return tree_sitter_python()
        case .ruby:
            return tree_sitter_ruby()
        case .rust:
            return tree_sitter_rust()
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
        .c,
        .css,
        .go,
        .goMod,
        .html,
        .java,
        .json,
        .python,
        .ruby,
        .rust,
        .swift,
        .yaml
    ]

    /// A ``CodeLanguage`` structure for `C`
    static let c: CodeLanguage = .init(id: .c, displayName: "C", extensions: ["c", "h", "o"])

    /// A ``CodeLanguage`` structure for `CSS`
    static let css: CodeLanguage = .init(id: .css, displayName: "CSS", extensions: ["css"])

    /// A ``CodeLanguage`` structure for `Go`
    static let go: CodeLanguage = .init(id: .go, displayName: "Go", extensions: ["go"])

    /// A ``CodeLanguage`` structure for `GoMod`
    static let goMod: CodeLanguage = .init(id: .goMod, displayName: "GoMod", extensions: ["mod"])

    /// A ``CodeLanguage`` structure for `HTML`
    static let html: CodeLanguage = .init(id: .html, displayName: "HTML", extensions: ["html", "htm"])

    /// A ``CodeLanguage`` structure for `Java`
    static let java: CodeLanguage = .init(id: .java, displayName: "Java", extensions: ["java"])

    /// A ``CodeLanguage`` structure for `JSON`
    static let json: CodeLanguage = .init(id: .json, displayName: "JSON", extensions: ["json"])

    /// A ``CodeLanguage`` structure for `Python`
    static let python: CodeLanguage = .init(id: .python, displayName: "Python", extensions: ["py"])

    /// A ``CodeLanguage`` structure for `Ruby`
    static let ruby: CodeLanguage = .init(id: .ruby, displayName: "Ruby", extensions: ["rb"])

    /// A ``CodeLanguage`` structure for `Rust`
    static let rust: CodeLanguage = .init(id: .rust, displayName: "Rust", extensions: ["rs"])

    /// A ``CodeLanguage`` structure for `Swift`
    static let swift: CodeLanguage = .init(id: .swift, displayName: "Swift", extensions: ["swift"])

    /// A ``CodeLanguage`` structure for `YAML`
    static let yaml: CodeLanguage = .init(id: .yaml, displayName: "YAML", extensions: ["yml", "yaml"])
}
