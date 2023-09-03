import XCTest
@testable import CodeEditInputView

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

    func test_delete() {
        var tree = TextLineStorage<TextLine>()
        func createTree() -> TextLineStorage<TextLine> {
            let tree = TextLineStorage<TextLine>()
            var data = [TextLineStorage<TextLine>.BuildItem]()
            for i in 0..<15 {
                data.append(.init(data: TextLine(), length: i + 1))
            }
            tree.build(from: data, estimatedLineHeight: 1.0)
            return tree
        }

        // Single Element
        tree.insert(line: TextLine(), atIndex: 0, length: 1, height: 1.0)
        XCTAssert(tree.length == 1, "Tree length incorrect")
        tree.delete(lineAt: 0)
        XCTAssert(tree.length == 0, "Tree failed to delete single node")
        XCTAssert(tree.root == nil, "Tree root should be nil")

        // Delete first

        tree = createTree()
        tree.delete(lineAt: 0)
        XCTAssert(tree.count == 14, "Tree length incorrect")
        XCTAssert(tree.first?.range.length == 2, "Failed to delete leftmost node")

        // Delete last

        tree = createTree()
        tree.delete(lineAt: tree.length - 1)
        XCTAssert(tree.count == 14, "Tree length incorrect")
        XCTAssert(tree.last?.range.length == 14, "Failed to delete rightmost node")

        // Delete mid leaf

        tree = createTree()
        tree.delete(lineAt: tree.length/2)
        XCTAssert(tree.root?.right?.left?.right == nil, "Failed to delete node 11")
        XCTAssert((tree.root?.right?.left?.left?.length ?? 0) == 9, "Left node of parent of deleted node is incorrect.")
        XCTAssert(tree.count == 14, "Tree length incorrect")

        // Delete root

        tree = createTree()
        tree.delete(lineAt: tree.root!.leftSubtreeOffset + 1)
        XCTAssert(tree.root?.color == .black, "Root color incorrect")
        XCTAssert(tree.root?.right?.left?.left == nil, "Replacement node was not moved to root")
        XCTAssert(tree.root?.leftSubtreeCount == 7, "Replacement node was not given correct metadata.")
        XCTAssert(tree.root?.leftSubtreeHeight == 7.0, "Replacement node was not given correct metadata.")
        XCTAssert(tree.root?.leftSubtreeOffset == 28, "Replacement node was not given correct metadata.")
        XCTAssert(tree.count == 14, "Tree length incorrect")

        // Delete a bunch of random

        for _ in 0..<20 {
            tree = createTree()
            tree.delete(lineAt: Int.random(in: 0..<tree.count ))
            XCTAssert(tree.count == 14, "Tree length incorrect")
            var last = -1
            for line in tree {
                XCTAssert(line.range.length > last, "Out of order after deletion")
                last = line.range.length
            }
        }
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
