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
        printTree(tree)
        tree.delete(lineAt: 45)
        printTree(tree)
        XCTAssert(tree.root?.right?.left?.length == 11, "Failed to remove node 10")
        XCTAssert(tree.root?.right?.leftSubtreeOffset == 20, "Failed to update metadata on parent of node 10")
        XCTAssert(tree.root?.right?.left?.right == nil, "Failed to replace node 10 with node 11")
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

public func printTree(_ tree: TextLineStorage<TextLine>) {
    print(
        treeString(tree.root!) { node in
            (
                // swiftlint:disable:next line_length
                "\(node.length)[\(node.leftSubtreeOffset)\(node.color == .red ? "R" : "B")][\(node.height), \(node.leftSubtreeHeight)]",
                node.left,
                node.right
            )
        }
    )
    print("")
}

// swiftlint:disable all
// Awesome tree printing function from https://stackoverflow.com/a/43903427/10453550
public func treeString<T>(_ node:T, reversed:Bool=false, isTop:Bool=true, using nodeInfo:(T)->(String,T?,T?)) -> String {
    // node value string and sub nodes
    let (stringValue, leftNode, rightNode) = nodeInfo(node)

    let stringValueWidth  = stringValue.count

    // recurse to sub nodes to obtain line blocks on left and right
    let leftTextBlock     = leftNode  == nil ? []
    : treeString(leftNode!,reversed:reversed,isTop:false,using:nodeInfo)
        .components(separatedBy:"\n")

    let rightTextBlock    = rightNode == nil ? []
    : treeString(rightNode!,reversed:reversed,isTop:false,using:nodeInfo)
        .components(separatedBy:"\n")

    // count common and maximum number of sub node lines
    let commonLines       = min(leftTextBlock.count,rightTextBlock.count)
    let subLevelLines     = max(rightTextBlock.count,leftTextBlock.count)

    // extend lines on shallower side to get same number of lines on both sides
    let leftSubLines      = leftTextBlock
    + Array(repeating:"", count: subLevelLines-leftTextBlock.count)
    let rightSubLines     = rightTextBlock
    + Array(repeating:"", count: subLevelLines-rightTextBlock.count)

    // compute location of value or link bar for all left and right sub nodes
    //   * left node's value ends at line's width
    //   * right node's value starts after initial spaces
    let leftLineWidths    = leftSubLines.map{$0.count}
    let rightLineIndents  = rightSubLines.map{$0.prefix{$0==" "}.count  }

    // top line value locations, will be used to determine position of current node & link bars
    let firstLeftWidth    = leftLineWidths.first   ?? 0
    let firstRightIndent  = rightLineIndents.first ?? 0


    // width of sub node link under node value (i.e. with slashes if any)
    // aims to center link bars under the value if value is wide enough
    //
    // ValueLine:    v     vv    vvvvvv   vvvvv
    // LinkLine:    / \   /  \    /  \     / \
    //
    let linkSpacing       = min(stringValueWidth, 2 - stringValueWidth % 2)
    let leftLinkBar       = leftNode  == nil ? 0 : 1
    let rightLinkBar      = rightNode == nil ? 0 : 1
    let minLinkWidth      = leftLinkBar + linkSpacing + rightLinkBar
    let valueOffset       = (stringValueWidth - linkSpacing) / 2

    // find optimal position for right side top node
    //   * must allow room for link bars above and between left and right top nodes
    //   * must not overlap lower level nodes on any given line (allow gap of minSpacing)
    //   * can be offset to the left if lower subNodes of right node
    //     have no overlap with subNodes of left node
    let minSpacing        = 2
    let rightNodePosition = zip(leftLineWidths,rightLineIndents[0..<commonLines])
        .reduce(firstLeftWidth + minLinkWidth)
    { max($0, $1.0 + minSpacing + firstRightIndent - $1.1) }


    // extend basic link bars (slashes) with underlines to reach left and right
    // top nodes.
    //
    //        vvvvv
    //       __/ \__
    //      L       R
    //
    let linkExtraWidth    = max(0, rightNodePosition - firstLeftWidth - minLinkWidth )
    let rightLinkExtra    = linkExtraWidth / 2
    let leftLinkExtra     = linkExtraWidth - rightLinkExtra

    // build value line taking into account left indent and link bar extension (on left side)
    let valueIndent       = max(0, firstLeftWidth + leftLinkExtra + leftLinkBar - valueOffset)
    let valueLine         = String(repeating:" ", count:max(0,valueIndent))
    + stringValue
    let slash             = reversed ? "\\" : "/"
    let backSlash         = reversed ? "/"  : "\\"
    let uLine             = reversed ? "¯"  : "_"
    // build left side of link line
    let leftLink          = leftNode == nil ? ""
    : String(repeating: " ", count:firstLeftWidth)
    + String(repeating: uLine, count:leftLinkExtra)
    + slash

    // build right side of link line (includes blank spaces under top node value)
    let rightLinkOffset   = linkSpacing + valueOffset * (1 - leftLinkBar)
    let rightLink         = rightNode == nil ? ""
    : String(repeating:  " ", count:rightLinkOffset)
    + backSlash
    + String(repeating:  uLine, count:rightLinkExtra)

    // full link line (will be empty if there are no sub nodes)
    let linkLine          = leftLink + rightLink

    // will need to offset left side lines if right side sub nodes extend beyond left margin
    // can happen if left subtree is shorter (in height) than right side subtree
    let leftIndentWidth   = max(0,firstRightIndent - rightNodePosition)
    let leftIndent        = String(repeating:" ", count:leftIndentWidth)
    let indentedLeftLines = leftSubLines.map{ $0.isEmpty ? $0 : (leftIndent + $0) }

    // compute distance between left and right sublines based on their value position
    // can be negative if leading spaces need to be removed from right side
    let mergeOffsets      = indentedLeftLines
        .map{$0.count}
        .map{leftIndentWidth + rightNodePosition - firstRightIndent - $0 }
        .enumerated()
        .map{ rightSubLines[$0].isEmpty ? 0  : $1 }


    // combine left and right lines using computed offsets
    //   * indented left sub lines
    //   * spaces between left and right lines
    //   * right sub line with extra leading blanks removed.
    let mergedSubLines    = zip(mergeOffsets.enumerated(),indentedLeftLines)
        .map{ ( $0.0, $0.1, $1 + String(repeating:" ", count:max(0,$0.1)) ) }
        .map{ $2 + String(rightSubLines[$0].dropFirst(max(0,-$1))) }

    // Assemble final result combining
    //  * node value string
    //  * link line (if any)
    //  * merged lines from left and right sub trees (if any)
    let treeLines = [leftIndent + valueLine]
    + (linkLine.isEmpty ? [] : [leftIndent + linkLine])
    + mergedSubLines

    return (reversed && isTop ? treeLines.reversed(): treeLines)
        .joined(separator:"\n")
}
// swiftlint:enable all
