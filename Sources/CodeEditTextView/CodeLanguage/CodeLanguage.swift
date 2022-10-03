//
//  CodeLanguage.swift
//  CodeEditTextView/CodeLanguage
//
//  Created by Lukas Pistrol on 25.05.22.
//

import Foundation
import tree_sitter
import SwiftTreeSitter

import TreeSitterBash
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
import TreeSitterZig

/// A structure holding metadata for code languages
public struct CodeLanguage {
    private init(
        id: TreeSitterLanguage,
        tsName: String,
        extensions: Set<String>,
        parentURL: URL? = nil,
        highlights: Set<String>? = nil
    ) {
        self.id = id
        self.tsName = tsName
        self.extensions = extensions
        self.parentQueryURL = parentURL
        self.additionalHighlights = highlights
    }

    /// The ID of the language
    public let id: TreeSitterLanguage

    /// The display name of the language
    public let tsName: String

    /// A set of file extensions for the language
    public let extensions: Set<String>

    /// The query URL of a language this language inherits from. (e.g.: C for C++)
    public let parentQueryURL: URL?

    /// Additional highlight file names (e.g.: JSX for JavaScript)
    public let additionalHighlights: Set<String>?

    /// The query URL for the language if available
    public var queryURL: URL? {
        queryURL()
    }

    /// The bundle's resource URL
    internal var resourceURL: URL? = Bundle.main.resourceURL

    /// The tree-sitter language for the language if available
    public var language: Language? {
        guard let tsLanguage = tsLanguage else { return nil }
        return Language(language: tsLanguage)
    }

    internal func queryURL(for highlights: String = "highlights") -> URL? {
        resourceURL?
            .appendingPathComponent("TreeSitter\(tsName)_TreeSitter\(tsName).bundle")
            .appendingPathComponent("Contents/Resources/queries/\(highlights).scm")
    }

    /// Gets the TSLanguage from `tree-sitter`
    private var tsLanguage: UnsafeMutablePointer<TSLanguage>? {
        switch id {
        case .bash:
            return tree_sitter_bash()
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
        case .jsx:
            return tree_sitter_javascript()
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
        case .zig:
            return tree_sitter_zig()
        case .plainText:
            return nil
        }
    }
}

public extension CodeLanguage {

    /// Gets the corresponding language for the given file URL
    ///
    /// Uses the `pathExtension` URL component to detect the language
    /// - Parameter url: The URL to get the language for.
    /// - Returns: A language structure
    static func detectLanguageFrom(url: URL) -> CodeLanguage {
        let fileExtension = url.pathExtension.lowercased()
        let fileName = url.pathComponents.last?.lowercased()
        // This is to handle special file types without an extension (e.g., Makefile, Dockerfile)
        let fileNameOrExtension = fileExtension.isEmpty ? (fileName != nil ? fileName! : "") : fileExtension
        if let lang = allLanguages.first(where: { lang in lang.extensions.contains(fileNameOrExtension)}) {
            return lang
        } else {
            return .default
        }
    }

    /// An array of all language structures.
    static let allLanguages: [CodeLanguage] = [
        .bash,
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
        .jsx,
        .php,
        .python,
        .ruby,
        .rust,
        .swift,
        .yaml,
        .zig
    ]

    /// A language structure for `Bash`
    static let bash: CodeLanguage = .init(id: .bash, tsName: "Bash", extensions: ["sh"])

    /// A language structure for `C`
    static let c: CodeLanguage = .init(id: .c, tsName: "C", extensions: ["c", "h", "o"])

    /// A language structure for `C++`
    static let cpp: CodeLanguage = .init(id: .cpp,
                                         tsName: "CPP",
                                         extensions: ["cpp", "h", "cc"],
                                         parentURL: CodeLanguage.c.queryURL)

    /// A language structure for `C#`
    static let cSharp: CodeLanguage = .init(id: .cSharp, tsName: "CSharp", extensions: ["cs"])

    /// A language structure for `CSS`
    static let css: CodeLanguage = .init(id: .css, tsName: "CSS", extensions: ["css"])

    /// A language structure for `Go`
    static let go: CodeLanguage = .init(id: .go, tsName: "Go", extensions: ["go"])

    /// A language structure for `GoMod`
    static let goMod: CodeLanguage = .init(id: .goMod, tsName: "GoMod", extensions: ["mod"])

    /// A language structure for `HTML`
    static let html: CodeLanguage = .init(id: .html, tsName: "HTML", extensions: ["html", "htm"])

    /// A language structure for `Java`
    static let java: CodeLanguage = .init(id: .java, tsName: "Java", extensions: ["java"])

    /// A language structure for `JavaScript`
    static let javascript: CodeLanguage = .init(id: .javascript, tsName: "JS", extensions: ["js"])

    /// A language structure for `JSON`
    static let json: CodeLanguage = .init(id: .json, tsName: "JSON", extensions: ["json"])

    /// A language structure for `JSX`
    static let jsx: CodeLanguage = .init(id: .jsx, tsName: "JS", extensions: ["jsx"], highlights: ["highlights-jsx"])

    /// A language structure for `PHP`
    static let php: CodeLanguage = .init(id: .php, tsName: "PHP", extensions: ["php"])

    /// A language structure for `Python`
    static let python: CodeLanguage = .init(id: .python, tsName: "Python", extensions: ["py"])

    /// A language structure for `Ruby`
    static let ruby: CodeLanguage = .init(id: .ruby, tsName: "Ruby", extensions: ["rb"])

    /// A language structure for `Rust`
    static let rust: CodeLanguage = .init(id: .rust, tsName: "Rust", extensions: ["rs"])

    /// A language structure for `Swift`
    static let swift: CodeLanguage = .init(id: .swift, tsName: "Swift", extensions: ["swift"])

    /// A language structure for `YAML`
    static let yaml: CodeLanguage = .init(id: .yaml, tsName: "YAML", extensions: ["yml", "yaml"])

    /// A language structure for `Zig`
    static let zig: CodeLanguage = .init(id: .zig, tsName: "Zig", extensions: ["zig"])

    /// The default language (plain text)
    static let `default`: CodeLanguage = .init(id: .plainText, tsName: "Plain Text", extensions: ["txt"])
}
