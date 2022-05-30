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
import TreeSitterCPP
import TreeSitterCSharp
import TreeSitterCSS
import TreeSitterGo
import TreeSitterGoMod
import TreeSitterHTML
import TreeSitterJava
import TreeSitterJS
import TreeSitterJSON
import TreeSitterPHP
import TreeSitterPython
import TreeSitterRuby
import TreeSitterRust
import TreeSitterSwift
import TreeSitterYAML

/// A structure holding metadata for code languages
public struct CodeLanguage {
    /// The ID of the language
    public let id: TreeSitterLanguage

    /// The display name of the language
    public let displayName: String

    /// A set of file extensions for the language
    public let extensions: Set<String>

    /// The query URL for the language if available
    public var queryURL: URL? {
        Bundle.main.resourceURL?
            .appendingPathComponent(bundle)
            .appendingPathComponent(highlights)
    }

    /// The query URL of a language this language inherits from. (e.g.: C for C++)
    public var parentQueryURL: URL?

    private var bundle: String {
        "TreeSitter\(displayName)_TreeSitter\(displayName).bundle"
    }

    private var highlights: String {
        "Contents/Resources/queries/highlights.scm"
    }

    /// The tree-sitter language for the language if available
    public var language: Language? {
        guard let ts_language = ts_language else { return nil }
        return Language(language: ts_language)
    }

    private var ts_language: UnsafeMutablePointer<TSLanguage>? {
        switch id {
        case .c:
            return tree_sitter_c()
        case .cpp:
            return tree_sitter_cpp()
        case .cSharp:
            return tree_sitter_c_sharp()
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
        case .javascript:
            return tree_sitter_javascript()
        case .json:
            return tree_sitter_json()
        case .php:
            return tree_sitter_php()
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

    /// Gets the corresponding language for the given file URL
    ///
    /// Uses the `pathExtension` URL component to detect the language
    /// - Parameter url: The URL to get the language for.
    /// - Returns: A language structure
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

    /// The default language (plain text)
    public static let `default` = CodeLanguage(
        id: .plainText,
        displayName: "Plain Text",
        extensions: ["txt"]
    )
}

public extension CodeLanguage {

    /// A collection of available language structures.
    static let knownLanguages: [CodeLanguage] = [
        .c,
        .cpp,
        .cSharp,
        .css,
        .go,
        .goMod,
        .html,
        .java,
        .javascript,
        .json,
        .php,
        .python,
        .ruby,
        .rust,
        .swift,
        .yaml
    ]

    /// A language structure for `C`
    static let c: CodeLanguage = .init(id: .c, displayName: "C", extensions: ["c", "h", "o"])

    /// A language structure for `C++`
    static let cpp: CodeLanguage = .init(id: .cpp,
                                         displayName: "CPP",
                                         extensions: ["cpp", "h", "cc"],
                                         parentQueryURL: CodeLanguage.c.queryURL)

    /// A language structure for `C#`
    static let cSharp: CodeLanguage = .init(id: .cSharp, displayName: "CSharp", extensions: ["cs"])

    /// A language structure for `CSS`
    static let css: CodeLanguage = .init(id: .css, displayName: "CSS", extensions: ["css"])

    /// A language structure for `Go`
    static let go: CodeLanguage = .init(id: .go, displayName: "Go", extensions: ["go"])

    /// A language structure for `GoMod`
    static let goMod: CodeLanguage = .init(id: .goMod, displayName: "GoMod", extensions: ["mod"])

    /// A language structure for `HTML`
    static let html: CodeLanguage = .init(id: .html, displayName: "HTML", extensions: ["html", "htm"])

    /// A language structure for `Java`
    static let java: CodeLanguage = .init(id: .java, displayName: "Java", extensions: ["java"])

    /// A language structure for `JavaScript`
    static let javascript: CodeLanguage = .init(id: .javascript, displayName: "JS", extensions: ["js"])

    /// A language structure for `JSON`
    static let json: CodeLanguage = .init(id: .json, displayName: "JSON", extensions: ["json"])

    /// A language structure for `PHP`
    static let php: CodeLanguage = .init(id: .php, displayName: "PHP", extensions: ["php"])

    /// A language structure for `Python`
    static let python: CodeLanguage = .init(id: .python, displayName: "Python", extensions: ["py"])

    /// A language structure for `Ruby`
    static let ruby: CodeLanguage = .init(id: .ruby, displayName: "Ruby", extensions: ["rb"])

    /// A language structure for `Rust`
    static let rust: CodeLanguage = .init(id: .rust, displayName: "Rust", extensions: ["rs"])

    /// A language structure for `Swift`
    static let swift: CodeLanguage = .init(id: .swift, displayName: "Swift", extensions: ["swift"])

    /// A language structure for `YAML`
    static let yaml: CodeLanguage = .init(id: .yaml, displayName: "YAML", extensions: ["yml", "yaml"])
}
