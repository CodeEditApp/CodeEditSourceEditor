import XCTest
@testable import CodeEditTextView

final class TextLayoutLineStorageTests: XCTestCase {
    func test_insert() {
        let tree = TextLineStorage<TextLine>()
        var sum = 0
        for i in 0..<20 {
            tree.insert(
                line: TextLine(),
                atIndex: sum,
                length: i + 1,
                height: 1.0
            )
            sum += i + 1
        }
        XCTAssert(tree.getLine(atIndex: 2)?.range.length == 2, "Found line incorrect, expected length of 2.")
        XCTAssert(tree.getLine(atIndex: 36)?.range.length == 9, "Found line incorrect, expected length of 9.")
    }

    func test_update() {
        let tree = TextLineStorage<TextLine>()
        var sum = 0
        for i in 0..<20 {
            tree.insert(
                line: TextLine(),
                atIndex: sum,
                length: i + 1,
                height: 1.0
            )
            sum += i + 1
        }
        tree.update(atIndex: 7, delta: 1, deltaHeight: 0)
        // TODO:
//        XCTAssert(tree.getLine(atIndex: 7)?.range.length == 8, "")
    }

    func test_insertPerformance() {
        let tree = TextLineStorage<TextLine>()
        var lines: [TextLineStorage<TextLine>.BuildItem] = []
        for i in 0..<250_000 {
            lines.append(TextLineStorage<TextLine>.BuildItem(
                data: TextLine(),
                length: i + 1
            ))
        }
        tree.build(from: lines, estimatedLineHeight: 1.0)
        // Measure time when inserting randomly into an already built tree.
        measure {
            for _ in 0..<100_000 {
                tree.insert(
                    line: TextLine(), atIndex: Int.random(in: 0..<tree.length), length: 1, height: 0.0
                )
            }
        }
    }

    func test_insertFastPerformance() {
        let tree = TextLineStorage<TextLine>()
        let lines: [TextLineStorage<TextLine>.BuildItem] = (0..<250_000).map {
            TextLineStorage<TextLine>.BuildItem(
                data: TextLine(),
                length: $0 + 1
            )
        }
        measure {
            tree.build(from: lines, estimatedLineHeight: 1.0)
        }
    }

    func test_iterationPerformance() {
        let tree = TextLineStorage<TextLine>()
        var lines: [TextLineStorage<TextLine>.BuildItem] = []
        for i in 0..<100_000 {
            lines.append(TextLineStorage<TextLine>.BuildItem(
                data: TextLine(),
                length: i + 1
            ))
        }
        tree.build(from: lines, estimatedLineHeight: 1.0)

        measure {
            for line in tree {
                let _ = line
            }
        }
    }
}
