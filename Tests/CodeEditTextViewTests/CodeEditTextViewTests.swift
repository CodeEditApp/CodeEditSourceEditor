import XCTest
@testable import CodeEditTextView
import SwiftTreeSitter

// swiftlint:disable all
final class CodeEditTextViewTests: XCTestCase {

    // MARK: NSFont Line Height

    func test_LineHeight() throws {
        let font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        let result = font.lineHeight
        let expected = 15.0
        XCTAssertEqual(result, expected)
    }

    func test_LineHeight2() throws {
        let font = NSFont.monospacedSystemFont(ofSize: 0, weight: .regular)
        let result = font.lineHeight
        let expected = 16.0
        XCTAssertEqual(result, expected)
    }

    // MARK: String NSRange

    func test_StringSubscriptNSRange() throws {
        let testString = "Hello, World"
        let testRange = NSRange(location: 7, length: 5)

        let result = String(testString[testRange]!)
        let expected = "World"
        XCTAssertEqual(result, expected)
    }

    func test_StringSubscriptNSRange2() throws {
        let testString = "Hello,\nWorld"
        let testRange = NSRange(location: 7, length: 5)

        let result = String(testString[testRange]!)
        let expected = "World"
        XCTAssertEqual(result, expected)
    }

    // MARK: Bash

    func test_CodeLanguageBash() throws {
        let url = URL(fileURLWithPath: "~/path/to/file.sh")
        let language = CodeLanguage.detectLanguageFrom(url: url)

        XCTAssertEqual(language.id, .bash)
    }

    // MARK: C

    func test_CodeLanguageC() throws {
        let url = URL(fileURLWithPath: "~/path/to/file.c")
        let language = CodeLanguage.detectLanguageFrom(url: url)

        XCTAssertEqual(language.id, .c)
    }

    func test_CodeLanguageC2() throws {
        let url = URL(fileURLWithPath: "~/path/to/file.o")
        let language = CodeLanguage.detectLanguageFrom(url: url)

        XCTAssertEqual(language.id, .c)
    }

    func test_CodeLanguageC3() throws {
        let url = URL(fileURLWithPath: "~/path/to/file.h")
        let language = CodeLanguage.detectLanguageFrom(url: url)

        XCTAssertEqual(language.id, .c)
    }

    // MARK: C++

    func test_CodeLanguageCPP() throws {
        let url = URL(fileURLWithPath: "~/path/to/file.cc")
        let language = CodeLanguage.detectLanguageFrom(url: url)

        XCTAssertEqual(language.id, .cpp)
    }

    func test_CodeLanguageCPP2() throws {
        let url = URL(fileURLWithPath: "~/path/to/file.cpp")
        let language = CodeLanguage.detectLanguageFrom(url: url)

        XCTAssertEqual(language.id, .cpp)
    }

    // MARK: C#

    func test_CodeLanguageCSharp() throws {
        let url = URL(fileURLWithPath: "~/path/to/file.cs")
        let language = CodeLanguage.detectLanguageFrom(url: url)

        XCTAssertEqual(language.id, .cSharp)
    }

    // MARK: CSS

    func test_CodeLanguageCSS() throws {
        let url = URL(fileURLWithPath: "~/path/to/file.css")
        let language = CodeLanguage.detectLanguageFrom(url: url)

        XCTAssertEqual(language.id, .css)
    }

    // MARK: Go

    func test_CodeLanguageGo() throws {
        let url = URL(fileURLWithPath: "~/path/to/file.go")
        let language = CodeLanguage.detectLanguageFrom(url: url)

        XCTAssertEqual(language.id, .go)
    }

    // MARK: Go Mod

    func test_CodeLanguageGoMod() throws {
        let url = URL(fileURLWithPath: "~/path/to/file.mod")
        let language = CodeLanguage.detectLanguageFrom(url: url)

        XCTAssertEqual(language.id, .goMod)
    }

    // MARK: Haskell

    func test_CodeLanguageHaskell() throws {
        let url = URL(fileURLWithPath: "~/path/to/file.hs")
        let language = CodeLanguage.detectLanguageFrom(url: url)

        XCTAssertEqual(language.id, .haskell)
    }

    // MARK: HTML

    func test_CodeLanguageHTML() throws {
        let url = URL(fileURLWithPath: "~/path/to/file.html")
        let language = CodeLanguage.detectLanguageFrom(url: url)

        XCTAssertEqual(language.id, .html)
    }

    func test_CodeLanguageHTML2() throws {
        let url = URL(fileURLWithPath: "~/path/to/file.htm")
        let language = CodeLanguage.detectLanguageFrom(url: url)

        XCTAssertEqual(language.id, .html)
    }

    // MARK: Java

    func test_CodeLanguageJava() throws {
        let url = URL(fileURLWithPath: "~/path/to/file.java")
        let language = CodeLanguage.detectLanguageFrom(url: url)

        XCTAssertEqual(language.id, .java)
    }

    // MARK: JavaScript

    func test_CodeLanguageJavaScript() throws {
        let url = URL(fileURLWithPath: "~/path/to/file.js")
        let language = CodeLanguage.detectLanguageFrom(url: url)

        XCTAssertEqual(language.id, .javascript)
    }

    // MARK: JSON

    func test_CodeLanguageJSON() throws {
        let url = URL(fileURLWithPath: "~/path/to/file.json")
        let language = CodeLanguage.detectLanguageFrom(url: url)

        XCTAssertEqual(language.id, .json)
    }

    // MARK: JSX

    func test_CodeLanguageJSX() throws {
        let url = URL(fileURLWithPath: "~/path/to/file.jsx")
        let language = CodeLanguage.detectLanguageFrom(url: url)

        XCTAssertEqual(language.id, .jsx)
    }

    // MARK: PHP

    func test_CodeLanguagePHP() throws {
        let url = URL(fileURLWithPath: "~/path/to/file.php")
        let language = CodeLanguage.detectLanguageFrom(url: url)

        XCTAssertEqual(language.id, .php)
    }

    // MARK: Python

    func test_CodeLanguagePython() throws {
        let url = URL(fileURLWithPath: "~/path/to/file.py")
        let language = CodeLanguage.detectLanguageFrom(url: url)

        XCTAssertEqual(language.id, .python)
    }

    // MARK: Ruby

    func test_CodeLanguageRuby() throws {
        let url = URL(fileURLWithPath: "~/path/to/file.rb")
        let language = CodeLanguage.detectLanguageFrom(url: url)

        XCTAssertEqual(language.id, .ruby)
    }

    // MARK: Rust

    func test_CodeLanguageRust() throws {
        let url = URL(fileURLWithPath: "~/path/to/file.rs")
        let language = CodeLanguage.detectLanguageFrom(url: url)

        XCTAssertEqual(language.id, .rust)
    }

    // MARK: Swift

    func test_CodeLanguageSwift() throws {
        let url = URL(fileURLWithPath: "~/path/to/file.swift")
        let language = CodeLanguage.detectLanguageFrom(url: url)

        XCTAssertEqual(language.id, .swift)
    }

    // MARK: YAML

    func test_CodeLanguageYAML() throws {
        let url = URL(fileURLWithPath: "~/path/to/file.yml")
        let language = CodeLanguage.detectLanguageFrom(url: url)

        XCTAssertEqual(language.id, .yaml)
    }

    func test_CodeLanguageYAML2() throws {
        let url = URL(fileURLWithPath: "~/path/to/file.yaml")
        let language = CodeLanguage.detectLanguageFrom(url: url)

        XCTAssertEqual(language.id, .yaml)
    }

    // MARK: Unsupported

    func test_CodeLanguageUnsupported() throws {
        let url = URL(fileURLWithPath: "~/path/to/file.abc")
        let language = CodeLanguage.detectLanguageFrom(url: url)

        XCTAssertEqual(language.id, .plainText)
    }

    let bundleURL = Bundle(for: TreeSitterModel.self).resourceURL

    func test_FetchQueryBash() throws {
        var language = CodeLanguage.bash
        language.resourceURL = bundleURL

        let data = try Data(contentsOf: language.queryURL!)
        let query = try? Query(language: language.language!, data: data)
        XCTAssertNotNil(query)
        XCTAssertNotEqual(query?.patternCount, 0)
    }

    func test_FetchQueryC() throws {
        var language = CodeLanguage.c
        language.resourceURL = bundleURL

        let data = try Data(contentsOf: language.queryURL!)
        let query = try? Query(language: language.language!, data: data)
        XCTAssertNotNil(query)
        XCTAssertNotEqual(query?.patternCount, 0)
    }

    func test_FetchQueryCPP() throws {
        var language = CodeLanguage.cpp
        language.resourceURL = bundleURL

        let data = try Data(contentsOf: language.queryURL!)
        let query = try? Query(language: language.language!, data: data)
        XCTAssertNotNil(query)
        XCTAssertNotEqual(query?.patternCount, 0)
    }

    func test_FetchQueryCSharp() throws {
        var language = CodeLanguage.cSharp
        language.resourceURL = bundleURL

        let data = try Data(contentsOf: language.queryURL!)
        let query = try? Query(language: language.language!, data: data)
        XCTAssertNotNil(query)
        XCTAssertNotEqual(query?.patternCount, 0)
    }

    func test_FetchQueryCSS() throws {
        var language = CodeLanguage.css
        language.resourceURL = bundleURL

        let data = try Data(contentsOf: language.queryURL!)
        let query = try? Query(language: language.language!, data: data)
        XCTAssertNotNil(query)
        XCTAssertNotEqual(query?.patternCount, 0)
    }

    func test_FetchQueryGo() throws {
        var language = CodeLanguage.go
        language.resourceURL = bundleURL

        let data = try Data(contentsOf: language.queryURL!)
        let query = try? Query(language: language.language!, data: data)
        XCTAssertNotNil(query)
        XCTAssertNotEqual(query?.patternCount, 0)
    }

    func test_FetchQueryGoMod() throws {
        var language = CodeLanguage.goMod
        language.resourceURL = bundleURL

        let data = try Data(contentsOf: language.queryURL!)
        let query = try? Query(language: language.language!, data: data)
        XCTAssertNotNil(query)
        XCTAssertNotEqual(query?.patternCount, 0)
    }

    func test_FetchQueryHTML() throws {
        var language = CodeLanguage.html
        language.resourceURL = bundleURL

        let data = try Data(contentsOf: language.queryURL!)
        let query = try? Query(language: language.language!, data: data)
        XCTAssertNotNil(query)
        XCTAssertNotEqual(query?.patternCount, 0)
    }

    func test_FetchQueryJava() throws {
        var language = CodeLanguage.java
        language.resourceURL = bundleURL

        let data = try Data(contentsOf: language.queryURL!)
        let query = try? Query(language: language.language!, data: data)
        XCTAssertNotNil(query)
        XCTAssertNotEqual(query?.patternCount, 0)
    }

    func test_FetchQueryJavaScript() throws {
        var language = CodeLanguage.javascript
        language.resourceURL = bundleURL

        let data = try Data(contentsOf: language.queryURL!)
        let query = try? Query(language: language.language!, data: data)
        XCTAssertNotNil(query)
        XCTAssertNotEqual(query?.patternCount, 0)
    }

    func test_FetchQueryJSON() throws {
        var language = CodeLanguage.json
        language.resourceURL = bundleURL

        let data = try Data(contentsOf: language.queryURL!)
        let query = try? Query(language: language.language!, data: data)
        XCTAssertNotNil(query)
        XCTAssertNotEqual(query?.patternCount, 0)
    }

    func test_FetchQueryJSX() throws {
        var language = CodeLanguage.jsx
        language.resourceURL = bundleURL

        let data = try Data(contentsOf: language.queryURL!)
        let query = try? Query(language: language.language!, data: data)
        XCTAssertNotNil(query)
        XCTAssertNotEqual(query?.patternCount, 0)
    }

    func test_FetchQueryPHP() throws {
        var language = CodeLanguage.php
        language.resourceURL = bundleURL

        let data = try Data(contentsOf: language.queryURL!)
        let query = try? Query(language: language.language!, data: data)
        XCTAssertNotNil(query)
        XCTAssertNotEqual(query?.patternCount, 0)
    }

    func test_FetchQueryPython() throws {
        var language = CodeLanguage.python
        language.resourceURL = bundleURL

        let data = try Data(contentsOf: language.queryURL!)
        let query = try? Query(language: language.language!, data: data)
        XCTAssertNotNil(query)
        XCTAssertNotEqual(query?.patternCount, 0)
    }

    func test_FetchQueryRuby() throws {
        var language = CodeLanguage.ruby
        language.resourceURL = bundleURL

        let data = try Data(contentsOf: language.queryURL!)
        let query = try? Query(language: language.language!, data: data)
        XCTAssertNotNil(query)
        XCTAssertNotEqual(query?.patternCount, 0)
    }

    func test_FetchQueryRust() throws {
        var language = CodeLanguage.rust
        language.resourceURL = bundleURL

        let data = try Data(contentsOf: language.queryURL!)
        let query = try? Query(language: language.language!, data: data)
        XCTAssertNotNil(query)
        XCTAssertNotEqual(query?.patternCount, 0)
    }

    func test_FetchQuerySwift() throws {
        var language = CodeLanguage.swift
        language.resourceURL = bundleURL

        let data = try Data(contentsOf: language.queryURL!)
        let query = try? Query(language: language.language!, data: data)
        XCTAssertNotNil(query)
        XCTAssertNotEqual(query?.patternCount, 0)
    }

}
