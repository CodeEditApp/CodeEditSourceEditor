//
//  File.swift
//  
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

public struct CodeLanguage {
    public let id: TreeSitterLanguage
    public let displayName: String
    public let extensions: Set<String>

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

    internal var language: Language? {
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

    static func detectLanguageFrom(url: URL) -> CodeLanguage {
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

    static let `default` = CodeLanguage(
        id: .plainText,
        displayName: "Plain Text",
        extensions: ["txt"]
    )
}

extension CodeLanguage {
    static let knownLanguages: [CodeLanguage] = [
        .go,
        .goMod,
        .html,
        .json,
        .ruby,
        .swift,
        .yaml
    ]

    static let go: CodeLanguage = .init(id: .go, displayName: "Go", extensions: ["go"])
    static let goMod: CodeLanguage = .init(id: .goMod, displayName: "GoMod", extensions: ["mod"])
    static let html: CodeLanguage = .init(id: .html, displayName: "HTML", extensions: ["html", "htm"])
    static let json: CodeLanguage = .init(id: .json, displayName: "JSON", extensions: ["json"])
    static let ruby: CodeLanguage = .init(id: .ruby, displayName: "Ruby", extensions: ["rb"])
    static let swift: CodeLanguage = .init(id: .swift, displayName: "Swift", extensions: ["swift"])
    static let yaml: CodeLanguage = .init(id: .yaml, displayName: "YAML", extensions: ["yml", "yaml"])
}
