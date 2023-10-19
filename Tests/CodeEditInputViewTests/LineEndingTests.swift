import XCTest
@testable import CodeEditInputView

// swiftlint:disable all

class LineEndingTests: XCTestCase {
    func test_lineEndingCreateUnix() {
        // The \n character
        XCTAssertTrue(LineEnding(rawValue: "\n") != nil, "Line ending failed to initialize with the \\n character")

        let line = "Loren Ipsum\n"
        XCTAssertTrue(LineEnding(line: line) != nil, "Line ending failed to initialize with a line ending in \\n")
    }

    func test_lineEndingCreateCRLF() {
        // The \r\n sequence
        XCTAssertTrue(LineEnding(rawValue: "\r\n") != nil, "Line ending failed to initialize with the \\r\\n sequence")

        let line = "Loren Ipsum\r\n"
        XCTAssertTrue(LineEnding(line: line) != nil, "Line ending failed to initialize with a line ending in \\r\\n")
    }

    func test_lineEndingCreateMacOS() {
        // The \r character
        XCTAssertTrue(LineEnding(rawValue: "\r") != nil, "Line ending failed to initialize with the \\r character")

        let line = "Loren Ipsum\r"
        XCTAssertTrue(LineEnding(line: line) != nil, "Line ending failed to initialize with a line ending in \\r")
    }

    func test_detectLineEndingDefault() {
        // There was a bug in this that caused it to flake sometimes, so we run this a couple times to ensure it's not flaky.
        // The odds of it being bad with the earlier bug after running 20 times is incredibly small
        for _ in 0..<20 {
            let storage = NSTextStorage(string: "hello world") // No line ending
            let lineStorage = TextLineStorage<TextLine>()
            lineStorage.buildFromTextStorage(storage, estimatedLineHeight: 10)
            let detected = LineEnding.detectLineEnding(lineStorage: lineStorage, textStorage: storage)
            XCTAssertTrue(detected == .lineFeed, "Default detected line ending incorrect, expected: \n, got: \(detected.rawValue.debugDescription)")
        }
    }

    func test_detectLineEndingUnix() {
        let corpus = "abcdefghijklmnopqrstuvwxyz123456789"
        let goalLineEnding = LineEnding.lineFeed

        let text = (10..<Int.random(in: 20..<100)).reduce("") { partialResult, _ in
            return partialResult + String((0..<Int.random(in: 1..<20)).map{ _ in corpus.randomElement()! }) + goalLineEnding.rawValue
        }

        let storage = NSTextStorage(string: text)
        let lineStorage = TextLineStorage<TextLine>()
        lineStorage.buildFromTextStorage(storage, estimatedLineHeight: 10)

        let detected = LineEnding.detectLineEnding(lineStorage: lineStorage, textStorage: storage)
        XCTAssertTrue(detected == goalLineEnding, "Incorrect detected line ending, expected: \(goalLineEnding.rawValue.debugDescription), got \(detected.rawValue.debugDescription)")
    }

    func test_detectLineEndingCLRF() {
        let corpus = "abcdefghijklmnopqrstuvwxyz123456789"
        let goalLineEnding = LineEnding.carriageReturnLineFeed

        let text = (10..<Int.random(in: 20..<100)).reduce("") { partialResult, _ in
            return partialResult + String((0..<Int.random(in: 1..<20)).map{ _ in corpus.randomElement()! }) + goalLineEnding.rawValue
        }

        let storage = NSTextStorage(string: text)
        let lineStorage = TextLineStorage<TextLine>()
        lineStorage.buildFromTextStorage(storage, estimatedLineHeight: 10)

        let detected = LineEnding.detectLineEnding(lineStorage: lineStorage, textStorage: storage)
        XCTAssertTrue(detected == goalLineEnding, "Incorrect detected line ending, expected: \(goalLineEnding.rawValue.debugDescription), got \(detected.rawValue.debugDescription)")
    }

    func test_detectLineEndingMacOS() {
        let corpus = "abcdefghijklmnopqrstuvwxyz123456789"
        let goalLineEnding = LineEnding.carriageReturn

        let text = (10..<Int.random(in: 20..<100)).reduce("") { partialResult, _ in
            return partialResult + String((0..<Int.random(in: 1..<20)).map{ _ in corpus.randomElement()! }) + goalLineEnding.rawValue
        }

        let storage = NSTextStorage(string: text)
        let lineStorage = TextLineStorage<TextLine>()
        lineStorage.buildFromTextStorage(storage, estimatedLineHeight: 10)

        let detected = LineEnding.detectLineEnding(lineStorage: lineStorage, textStorage: storage)
        XCTAssertTrue(detected == goalLineEnding, "Incorrect detected line ending, expected: \(goalLineEnding.rawValue.debugDescription), got \(detected.rawValue.debugDescription)")
    }
}

// swiftlint:enable all
