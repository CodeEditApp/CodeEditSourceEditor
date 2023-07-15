//
//  TextLayoutLineStorage.swift
//
//
//  Created by Khan Winter on 6/25/23.
//

import Foundation

/// Implements a red-black tree for efficiently editing, storing and retrieving `TextLine`s.
final class TextLineStorage {
#if DEBUG
    var root: Node?
#else
    private var root: Node?
#endif
    /// The number of characters in the storage object.
    private(set) public var length: Int = 0
    /// The number of lines in the storage object
    private(set) public var count: Int = 0

    init() { }

    // MARK: - Public Methods

    /// Inserts a new line for the given range.
    /// - Parameters:
    ///   - line: The text line to insert
    ///   - range: The range the line represents. If the range is empty the line will be ignored.
    public func insert(line: TextLine, atIndex index: Int, length: Int, height: CGFloat) {
        assert(index >= 0 && index <= self.length, "Invalid index, expected between 0 and \(self.length). Got \(index)")
        defer {
            self.count += 1
            self.length += length
        }

        let insertedNode = Node(
            length: length,
            line: line,
            leftSubtreeOffset: 0,
            leftSubtreeHeight: 0.0,
            height: height,
            color: .black
        )
        guard root != nil else {
            root = insertedNode
            return
        }
        insertedNode.color = .red

        var currentNode = root
        var currentOffset: Int = root?.leftSubtreeOffset ?? 0
        while let node = currentNode {
            if currentOffset >= index {
                if node.left != nil {
                    currentNode = node.left
                    currentOffset -= (node.left?.leftSubtreeOffset ?? 0) + (node.left?.length ?? 0)
                } else {
                    node.left = insertedNode
                    insertedNode.parent = node
                    currentNode = nil
                }
            } else {
                if node.right != nil {
                    currentNode = node.right
                    currentOffset += node.length + (node.right?.leftSubtreeOffset ?? 0)
                } else {
                    node.right = insertedNode
                    insertedNode.parent = node
                    currentNode = nil
                }
            }
        }

        insertFixup(node: insertedNode)
    }

    /// Fetches a line for the given index.
    ///
    /// Complexity: `O(log n)`
    /// - Parameter index: The index to fetch for.
    /// - Returns: A text line object representing a generated line object and the offset in the document of the line.
    ///            If the line was not found, the offset will be `-1`.
//    public func getLine(atIndex index: Int) -> (TextLine?, Int) {
//        let result = search(for: index)
//        return (result.0?.line, result.1)
//    }

    /// Applies a length change at the given index.
    ///
    /// If a character was deleted, delta should be negative.
    /// The `index` parameter should represent where the edit began.
    ///
    /// Complexity: `O(m log n)` where `m` is the number of lines that need to be deleted as a result of this update.
    /// and `n` is the number of lines stored in the tree.
    ///
    /// Lines will be deleted if the delta is both negative and encompasses the entire line.
    ///
    /// If the delta goes beyond the line's range, an error will be thrown.
    /// - Parameters:
    ///   - index: The index where the edit began
    ///   - delta: The change in length of the document. Negative for deletes, positive for insertions.
    ///   - deltaHeight: The change in height of the document.
    public func update(atIndex index: Int, delta: Int, deltaHeight: CGFloat) {
        assert(index >= 0 && index < self.length, "Invalid index, expected between 0 and \(self.length). Got \(index)")
        assert(delta != 0, "Delta must be non-0")
        let (node, offset) = search(for: index)
        guard let node, offset > -1 else { return }
        if delta < 0 {
            assert(
                index - offset > delta,
                "Delta too large. Deleting \(-delta) from line at position \(index) extends beyond the line's range."
            )
        }

        node.length += delta
        node.height += deltaHeight
        metaFixup(startingAt: node, delta: delta, deltaHeight: deltaHeight)
    }

    /// Deletes a line at the given index.
    ///
    /// Will return if a line could not be found for the given index, and throw an assertion error if the index is
    /// out of bounds.
    /// - Parameter index: The index to delete a line at.
    public func delete(lineAt index: Int) {
        assert(index >= 0 && index < self.length, "Invalid index, expected between 0 and \(self.length). Got \(index)")
//        guard let nodeZ = search(for: index).0 else { return }
//        var nodeX: Node
//        var nodeY: Node

    }

    public func printTree() {
        print(
            treeString(root!) { node in
                (
                    "\(node.length)[\(node.leftSubtreeOffset)\(node.color == .red ? "R" : "B")]",
                    node.left,
                    node.right
                )
            }
        )
    }
}

private extension TextLineStorage {
    // MARK: - Search

    /// Searches for the given index. Returns a node and offset if found.
    /// - Parameter index: The index to look for in the document.
    /// - Returns: A tuple containing a node if it was found, and the offset of the node in the document.
    ///            The index will be negative if the node was not found.
    func search(for index: Int) -> (Node?, Int) {
        var currentNode = root
        var currentOffset: Int = root?.leftSubtreeOffset ?? 0
        while let node = currentNode {
            // If index is in the range [currentOffset..<currentOffset + length) it's in the line
            if index >= currentOffset && index < currentOffset + node.length {
                return (node, currentOffset)
            } else if currentOffset > index {
                currentNode = node.left
                currentOffset -= (node.left?.leftSubtreeOffset ?? 0) + (node.left?.length ?? 0)
            } else if node.leftSubtreeOffset < index {
                currentNode = node.right
                currentOffset += node.length + (node.right?.leftSubtreeOffset ?? 0)
            } else {
                currentNode = nil
            }
        }

        return (nil, -1)
    }

    // MARK: - Fixup

    func insertFixup(node: Node) {
        metaFixup(startingAt: node, delta: node.length, deltaHeight: node.height)

        var nextNode: Node? = node
        while var nodeX = nextNode, nodeX != root, let nodeXParent = nodeX.parent, nodeXParent.color == .red {
            let nodeY = sibling(nodeXParent)
            if isLeftChild(nodeXParent) {
                if nodeY?.color == .red {
                    nodeXParent.color = .black
                    nodeY?.color = .black
                    nodeX.parent?.parent?.color = .red
                    nextNode = nodeX.parent?.parent
                } else {
                    if isRightChild(nodeX) {
                        nodeX = nodeXParent
                        leftRotate(node: nodeX)
                    }

                    nodeX.parent?.color = .black
                    nodeX.parent?.parent?.color = .red
                    if let grandparent = nodeX.parent?.parent {
                        rightRotate(node: grandparent)
                    }
                }
            } else {
                if nodeY?.color == .red {
                    nodeXParent.color = .black
                    nodeY?.color = .black
                    nodeX.parent?.parent?.color = .red
                    nextNode = nodeX.parent?.parent
                } else {
                    if isLeftChild(nodeX) {
                        nodeX = nodeXParent
                        rightRotate(node: nodeX)
                    }

                    nodeX.parent?.color = .black
                    nodeX.parent?.parent?.color = .red
                    if let grandparent = nodeX.parent?.parent {
                        leftRotate(node: grandparent)
                    }
                }
            }
        }

        root?.color = .black
    }

    /// RB Tree Deletes `:(`
    func deleteFixup(node: Node) {

    }

    /// Walk up the tree, updating any `leftSubtree` metadata.
    func metaFixup(startingAt node: Node, delta: Int, deltaHeight: CGFloat) {
        guard node.parent != nil, delta > 0 else { return }
        // Find the first node that needs to be updated (first left child)
        var nodeX: Node? = node
        var nodeXParent: Node? = node.parent
        while nodeX != nil {
            if nodeXParent?.right == nodeX {
                nodeX = nodeXParent
                nodeXParent = nodeX?.parent
            } else {
                nodeX = nil
            }
        }

        guard nodeX != nil else { return }
        while nodeX != root {
            if nodeXParent?.left == nodeX {
                nodeXParent?.leftSubtreeOffset += delta
                nodeXParent?.leftSubtreeHeight += deltaHeight
            }
            if nodeXParent != nil {
                count += 1
                nodeX = nodeXParent
                nodeXParent = nodeX?.parent
            } else {
                return
            }
        }
    }

    func calculateSize(_ node: Node?) -> Int {
        guard let node else { return 0 }
        return node.length + node.leftSubtreeOffset + calculateSize(node.right)
    }
}

// MARK: - Rotations

private extension TextLineStorage {
    func rightRotate(node: Node) {
        rotate(node: node, left: false)
    }

    func leftRotate(node: Node) {
        rotate(node: node, left: true)
    }

    func rotate(node: Node, left: Bool) {
        var nodeY: Node?

        if left {
            nodeY = node.right
            nodeY?.leftSubtreeOffset += node.leftSubtreeOffset + node.length
            nodeY?.leftSubtreeHeight += node.leftSubtreeHeight + node.height
            node.right = nodeY?.left
            node.right?.parent = node
        } else {
            nodeY = node.left
            node.left = nodeY?.right
            node.left?.parent = node
        }

        nodeY?.parent = node.parent
        if node.parent == nil {
            if let node = nodeY {
                root = node
            }
        } else if isLeftChild(node) {
            node.parent?.left = nodeY
        } else if isRightChild(node) {
            node.parent?.right = nodeY
        }

        if left {
            nodeY?.left = node
        } else {
            nodeY?.right = node
            node.leftSubtreeOffset = (node.left?.length ?? 0) + (node.left?.leftSubtreeOffset ?? 0)
            node.leftSubtreeHeight = (node.left?.height ?? 0) + (node.left?.leftSubtreeHeight ?? 0)
        }
        node.parent = nodeY
    }
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
