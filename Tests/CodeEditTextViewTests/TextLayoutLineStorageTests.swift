import XCTest
@testable import CodeEditTextView

final class TextLayoutLineStorageTests: XCTestCase {
    func test_insert() {
        let tree = TextLineStorage<TextLine>()
        let stringRef = NSTextStorage(string: "")
        var sum = 0
        for i in 0..<20 {
            tree.insert(
                line: .init(stringRef: stringRef, range: .init(location: 0, length: 0)),
                atIndex: sum,
                length: i + 1,
                height: 1.0
            )
            sum += i + 1
        }
        XCTAssert(tree.getLine(atIndex: 2)?.node.length == 2, "Found line incorrect, expected length of 2.")
        XCTAssert(tree.getLine(atIndex: 36)?.node.length == 9, "Found line incorrect, expected length of 9.")
    }

    func test_update() {
        let tree = TextLineStorage<TextLine>()
        let stringRef = NSTextStorage(string: "")
        var sum = 0
        for i in 0..<20 {
            tree.insert(
                line: .init(stringRef: stringRef, range: .init(location: 0, length: 0)),
                atIndex: sum,
                length: i + 1,
                height: 1.0
            )
            sum += i + 1
        }
    }

    func test_insertPerformance() {
        let tree = TextLineStorage<TextLine>()
        let stringRef = NSTextStorage(string: "")
        measure {
            for i in 0..<250_000 {
                tree.insert(line: .init(stringRef: stringRef, range: .init(location: 0, length: 0)), atIndex: i, length: 1, height: 0.0)
            }
        }
    }

    func test_insertFastPerformance() {
        let tree = TextLineStorage<TextLine>()
        let stringRef = NSTextStorage(string: "")
        measure {
            var lines: [(TextLine, Int)] = []
            for i in 0..<250_000 {
                lines.append((
                    TextLine(stringRef: stringRef, range: NSRange(location: i, length: 1)),
                    i + 1
                ))
            }
            tree.build(from: lines, estimatedLineHeight: 1.0)
        }
    }
}
