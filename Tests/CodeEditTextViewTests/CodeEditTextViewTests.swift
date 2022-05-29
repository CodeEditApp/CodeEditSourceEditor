import XCTest
@testable import CodeEditTextView

final class CodeEditTextViewTests: XCTestCase {

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

    func test_CodeLanguageSwift() throws {
        let url = URL(fileURLWithPath: "~/path/to/file.swift")
        let language = CodeLanguage.detectLanguageFrom(url: url)

        XCTAssertEqual(language.id, .swift)
    }

    func test_CodeLanguageGo() throws {
        let url = URL(fileURLWithPath: "~/path/to/file.go")
        let language = CodeLanguage.detectLanguageFrom(url: url)

        XCTAssertEqual(language.id, .go)
    }

    func test_CodeLanguageGoMod() throws {
        let url = URL(fileURLWithPath: "~/path/to/file.mod")
        let language = CodeLanguage.detectLanguageFrom(url: url)

        XCTAssertEqual(language.id, .goMod)
    }

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

    func test_CodeLanguageJSON() throws {
        let url = URL(fileURLWithPath: "~/path/to/file.json")
        let language = CodeLanguage.detectLanguageFrom(url: url)

        XCTAssertEqual(language.id, .json)
    }

    func test_CodeLanguageRuby() throws {
        let url = URL(fileURLWithPath: "~/path/to/file.rb")
        let language = CodeLanguage.detectLanguageFrom(url: url)

        XCTAssertEqual(language.id, .ruby)
    }

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

    func test_CodeLanguageUnsupported() throws {
        let url = URL(fileURLWithPath: "~/path/to/file.abc")
        let language = CodeLanguage.detectLanguageFrom(url: url)

        XCTAssertEqual(language.id, .plainText)
    }

}
