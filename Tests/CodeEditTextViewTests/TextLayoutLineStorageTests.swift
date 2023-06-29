import XCTest
@testable import CodeEditTextView

final class TextLayoutLineStorageTests: XCTestCase {
    func test_insert() {
        let tree = TextLayoutLineStorage()
        tree.insert(atIndex: 0, length: 1)
        tree.insert(atIndex: 1, length: 2)
        tree.insert(atIndex: 1, length: 3)
        tree.printTree()
        tree.insert(atIndex: 6, length: 4)
        tree.printTree()
        tree.insert(atIndex: 4, length: 5)
        tree.printTree()
        tree.insert(atIndex: 1, length: 6)
        tree.printTree()
        tree.insert(atIndex: 0, length: 7)
        tree.printTree()
        tree.insert(atIndex: 28, length: 8)
        tree.printTree()
        tree.insert(atIndex: 36, length: 9)
        tree.printTree()
        tree.insert(atIndex: 45, length: 10)
        tree.printTree()
        tree.insert(atIndex: 55, length: 11)
        tree.printTree()
        tree.insert(atIndex: 66, length: 12)
        tree.printTree()

        tree.update(atIndex: 18, delta: 2)
        tree.printTree()

        tree.update(atIndex: 28, delta: -2)
        tree.printTree()

//        print(tree.search(for: 7)?.length)
//        print(tree.search(for: 17)?.length)
//        print(tree.search(for: 0)?.length)

//        var n = tree.root?.minimum()
//        while let node = n {
//            print("\(node.length)", terminator: "")
//            n = node.getSuccessor()
//        }
        print("")
    }

    func test_insertInc() {
        let tree = TextLayoutLineStorage()
        for i in 0..<100_000 {
            tree.insert(atIndex: i, length: 1)
        }
    }

    func test_insertPerformance() {
        let tree = TextLayoutLineStorage()
        measure {
            for i in 0..<250_000 {
                tree.insert(atIndex: i, length: 1)
            }
        }
    }
}
