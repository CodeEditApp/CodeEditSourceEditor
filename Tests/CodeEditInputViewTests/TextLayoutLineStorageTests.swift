import XCTest
@testable import CodeEditInputView

// swiftlint:disable function_body_length

fileprivate extension CGFloat {
    func approxEqual(_ value: CGFloat) -> Bool {
        return abs(self - value) < 0.05
    }
}

final class TextLayoutLineStorageTests: XCTestCase {
    /// Creates a balanced height=3 tree useful for testing and debugging.
    /// - Returns: A new tree.
    fileprivate func createBalancedTree() -> TextLineStorage<TextLine> {
        let tree = TextLineStorage<TextLine>()
        var data = [TextLineStorage<TextLine>.BuildItem]()
        for idx in 0..<15 {
            data.append(.init(data: TextLine(), length: idx + 1))
        }
        tree.build(from: data, estimatedLineHeight: 1.0)
        return tree
    }

    /// Recursively checks that the given tree has the correct metadata everywhere.
    /// - Parameter tree: The tree to check.
    fileprivate func assertTreeMetadataCorrect(_ tree: TextLineStorage<TextLine>) throws {
        struct ChildData {
            let length: Int
            let count: Int
            let height: CGFloat
        }

        func checkChildren(_ node: TextLineStorage<TextLine>.Node<TextLine>?) -> ChildData {
            guard let node else { return ChildData(length: 0, count: 0, height: 0.0) }
            let leftSubtreeData = checkChildren(node.left)
            let rightSubtreeData = checkChildren(node.right)

            XCTAssert(leftSubtreeData.length == node.leftSubtreeOffset, "Left subtree length incorrect")
            XCTAssert(leftSubtreeData.count == node.leftSubtreeCount, "Left subtree node count incorrect")
            XCTAssert(leftSubtreeData.height.approxEqual(node.leftSubtreeHeight), "Left subtree height incorrect")

            return ChildData(
                length: node.length + leftSubtreeData.length + rightSubtreeData.length,
                count: 1 + leftSubtreeData.count + rightSubtreeData.count,
                height: node.height + leftSubtreeData.height + rightSubtreeData.height
            )
        }

        let rootData = checkChildren(tree.root)

        XCTAssert(rootData.count == tree.count, "Node count incorrect")
        XCTAssert(rootData.length == tree.length, "Length incorrect")
        XCTAssert(rootData.height.approxEqual(tree.height), "Height incorrect")

        var lastIdx = -1
        for line in tree {
            XCTAssert(lastIdx == line.index - 1, "Incorrect index found")
            lastIdx = line.index
        }
    }

    func test_insert() throws {
        var tree = TextLineStorage<TextLine>()

        // Single Element
        tree.insert(line: TextLine(), atIndex: 0, length: 1, height: 50.0)
        XCTAssert(tree.length == 1, "Tree length incorrect")
        XCTAssert(tree.count == 1, "Tree count incorrect")
        XCTAssert(tree.height == 50.0, "Tree height incorrect")
        XCTAssert(tree.root?.right == nil && tree.root?.left == nil, "Somehow inserted an extra node.")
        try assertTreeMetadataCorrect(tree)

        // Insert into first
        tree = createBalancedTree()
        tree.insert(line: TextLine(), atIndex: 0, length: 1, height: 1.0)
        try assertTreeMetadataCorrect(tree)

        // Insert into last
        tree = createBalancedTree()
        tree.insert(line: TextLine(), atIndex: tree.length - 1, length: 1, height: 1.0)
        try assertTreeMetadataCorrect(tree)

        tree = createBalancedTree()
        tree.insert(line: TextLine(), atIndex: 45, length: 1, height: 1.0)
        try assertTreeMetadataCorrect(tree)
    }

    func test_update() throws {
        var tree = TextLineStorage<TextLine>()

        // Single Element
        tree.insert(line: TextLine(), atIndex: 0, length: 1, height: 1.0)
        tree.update(atIndex: 0, delta: 20, deltaHeight: 5.0)
        XCTAssert(tree.length == 21, "Tree length incorrect")
        XCTAssert(tree.count == 1, "Tree count incorrect")
        XCTAssert(tree.height == 6, "Tree height incorrect")
        XCTAssert(tree.root?.right == nil && tree.root?.left == nil, "Somehow inserted an extra node.")
        try assertTreeMetadataCorrect(tree)

        // Update First
        tree = createBalancedTree()
        tree.update(atIndex: 0, delta: 12, deltaHeight: -0.5)
        XCTAssert(tree.height == 14.5, "Tree height incorrect")
        XCTAssert(tree.count == 15, "Tree count changed")
        XCTAssert(tree.length == 132, "Tree length incorrect")
        XCTAssert(tree.first?.range.length == 13, "First node wasn't updated correctly.")
        try assertTreeMetadataCorrect(tree)

        // Update Last
        tree = createBalancedTree()
        tree.update(atIndex: tree.length - 1, delta: -14, deltaHeight: 1.75)
        XCTAssert(tree.height == 16.75, "Tree height incorrect")
        XCTAssert(tree.count == 15, "Tree count changed")
        XCTAssert(tree.length == 106, "Tree length incorrect")
        XCTAssert(tree.last?.range.length == 1, "Last node wasn't updated correctly.")
        try assertTreeMetadataCorrect(tree)

        // Update middle
        tree = createBalancedTree()
        tree.update(atIndex: 45, delta: -9, deltaHeight: 1.0)
        XCTAssert(tree.height == 16.0, "Tree height incorrect")
        XCTAssert(tree.count == 15, "Tree count changed")
        XCTAssert(tree.length == 111, "Tree length incorrect")
        XCTAssert(tree.root?.right?.left?.height == 2.0 && tree.root?.right?.left?.length == 1, "Node wasn't updated")
        try assertTreeMetadataCorrect(tree)

        // Update at random
        tree = createBalancedTree()
        for _ in 0..<20 {
            let delta = Int.random(in: 1..<20)
            let deltaHeight = Double.random(in: 0..<20.0)
            let originalHeight = tree.height
            let originalCount = tree.count
            let originalLength = tree.length
            tree.update(atIndex: Int.random(in: 0..<tree.length), delta: delta, deltaHeight: deltaHeight)
            XCTAssert(originalCount == tree.count, "Tree count should not change on update")
            XCTAssert(originalHeight + deltaHeight == tree.height, "Tree height incorrect")
            XCTAssert(originalLength + delta == tree.length, "Tree length incorrect")
            try assertTreeMetadataCorrect(tree)
        }
    }

    func test_delete() throws {
        var tree = TextLineStorage<TextLine>()

        // Single Element
        tree.insert(line: TextLine(), atIndex: 0, length: 1, height: 1.0)
        XCTAssert(tree.length == 1, "Tree length incorrect")
        tree.delete(lineAt: 0)
        XCTAssert(tree.length == 0, "Tree failed to delete single node")
        XCTAssert(tree.root == nil, "Tree root should be nil")
        try assertTreeMetadataCorrect(tree)

        // Delete first

        tree = createBalancedTree()
        tree.delete(lineAt: 0)
        XCTAssert(tree.count == 14, "Tree length incorrect")
        XCTAssert(tree.first?.range.length == 2, "Failed to delete leftmost node")
        try assertTreeMetadataCorrect(tree)

        // Delete last

        tree = createBalancedTree()
        tree.delete(lineAt: tree.length - 1)
        XCTAssert(tree.count == 14, "Tree length incorrect")
        XCTAssert(tree.last?.range.length == 14, "Failed to delete rightmost node")
        try assertTreeMetadataCorrect(tree)

        // Delete mid leaf

        tree = createBalancedTree()
        tree.delete(lineAt: 45)
        XCTAssert(tree.root?.right?.left?.length == 11, "Failed to remove node 10")
        XCTAssert(tree.root?.right?.leftSubtreeOffset == 20, "Failed to update metadata on parent of node 10")
        XCTAssert(tree.root?.right?.left?.right == nil, "Failed to replace node 10 with node 11")
        XCTAssert(tree.count == 14, "Tree length incorrect")
        try assertTreeMetadataCorrect(tree)

        tree = createBalancedTree()
        tree.delete(lineAt: 66)
        XCTAssert(tree.root?.right?.length == 13, "Failed to remove node 12")
        XCTAssert(tree.root?.right?.leftSubtreeOffset == 30, "Failed to update metadata on parent of node 13")
        XCTAssert(tree.root?.right?.left?.right?.left == nil, "Failed to replace node 12 with node 13")
        XCTAssert(tree.count == 14, "Tree length incorrect")
        try assertTreeMetadataCorrect(tree)

        // Delete root

        tree = createBalancedTree()
        tree.delete(lineAt: tree.root!.leftSubtreeOffset + 1)
        XCTAssert(tree.root?.color == .black, "Root color incorrect")
        XCTAssert(tree.root?.right?.left?.left == nil, "Replacement node was not moved to root")
        XCTAssert(tree.root?.leftSubtreeCount == 7, "Replacement node was not given correct metadata.")
        XCTAssert(tree.root?.leftSubtreeHeight == 7.0, "Replacement node was not given correct metadata.")
        XCTAssert(tree.root?.leftSubtreeOffset == 28, "Replacement node was not given correct metadata.")
        XCTAssert(tree.count == 14, "Tree length incorrect")
        try assertTreeMetadataCorrect(tree)

        // Delete a bunch of random

        for _ in 0..<20 {
            tree = createBalancedTree()
            var lastCount = 15
            while !tree.isEmpty {
                lastCount -= 1
                tree.delete(lineAt: Int.random(in: 0..<tree.count))
                XCTAssert(tree.count == lastCount, "Tree length incorrect")
                var last = -1
                for line in tree {
                    XCTAssert(line.range.length > last, "Out of order after deletion")
                    last = line.range.length
                }
                try assertTreeMetadataCorrect(tree)
            }
        }
    }

    func test_insertPerformance() {
        let tree = TextLineStorage<TextLine>()
        var lines: [TextLineStorage<TextLine>.BuildItem] = []
        for idx in 0..<250_000 {
            lines.append(TextLineStorage<TextLine>.BuildItem(
                data: TextLine(),
                length: idx + 1
            ))
        }
        tree.build(from: lines, estimatedLineHeight: 1.0)
        // Measure time when inserting randomly into an already built tree.
        // Start    0.667s
        // 10/6/23  0.563s  -15.59%
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
        // Start    0.113s
        measure {
            tree.build(from: lines, estimatedLineHeight: 1.0)
        }
    }

    func test_iterationPerformance() {
        let tree = TextLineStorage<TextLine>()
        var lines: [TextLineStorage<TextLine>.BuildItem] = []
        for idx in 0..<100_000 {
            lines.append(TextLineStorage<TextLine>.BuildItem(
                data: TextLine(),
                length: idx + 1
            ))
        }
        tree.build(from: lines, estimatedLineHeight: 1.0)
        // Start    0.181s
        measure {
            for line in tree {
                _ = line
            }
        }
    }
}

// swiftlint:enable function_body_length
