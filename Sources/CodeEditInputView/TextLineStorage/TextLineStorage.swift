//
//  TextLayoutLineStorage.swift
//
//
//  Created by Khan Winter on 6/25/23.
//

import Foundation

/// Implements a red-black tree for efficiently editing, storing and retrieving lines of text in a document.
public final class TextLineStorage<Data: Identifiable> {
    private enum MetaFixupAction {
        case inserted
        case deleted
        case none
    }

    internal var root: Node<Data>?

    /// The number of characters in the storage object.
    private(set) public var length: Int = 0
    /// The number of lines in the storage object
    private(set) public var count: Int = 0

    public var isEmpty: Bool { count == 0 }

    public var height: CGFloat = 0

    public var first: TextLinePosition? {
        guard length > 0,
              let position = search(for: 0) else {
            return nil
        }
        return TextLinePosition(position: position)
    }

    public var last: TextLinePosition? {
        guard length > 0, let position = search(for: length - 1) else { return nil }
        return TextLinePosition(position: position)
    }

    public init() { }

    // MARK: - Public Methods

    /// Inserts a new line for the given range.
    /// - Parameters:
    ///   - line: The text line to insert
    ///   - range: The range the line represents. If the range is empty the line will be ignored.
    public func insert(line: Data, atIndex index: Int, length: Int, height: CGFloat) {
        assert(index >= 0 && index <= self.length, "Invalid index, expected between 0 and \(self.length). Got \(index)")
        defer {
            self.count += 1
            self.length += length
            self.height += height
        }

        let insertedNode = Node(
            length: length,
            data: line,
            leftSubtreeOffset: 0,
            leftSubtreeHeight: 0.0,
            leftSubtreeCount: 0,
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
                    currentOffset = (currentOffset - node.leftSubtreeOffset) + (node.left?.leftSubtreeOffset ?? 0)
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
    public func getLine(atIndex index: Int) -> TextLinePosition? {
        guard let nodePosition = search(for: index) else { return nil }
        return TextLinePosition(position: nodePosition)
    }

    /// Fetches a line for the given `y` value.
    ///
    /// Complexity: `O(log n)`
    /// - Parameter position: The position to fetch for.
    /// - Returns: A text line object representing a generated line object and the offset in the document of the line.
    public func getLine(atPosition posY: CGFloat) -> TextLinePosition? {
        var currentNode = root
        var currentOffset: Int = root?.leftSubtreeOffset ?? 0
        var currentYPosition: CGFloat = root?.leftSubtreeHeight ?? 0
        var currentIndex: Int = root?.leftSubtreeCount ?? 0
        while let node = currentNode {
            // If index is in the range [currentOffset..<currentOffset + length) it's in the line
            if posY >= currentYPosition && posY < currentYPosition + node.height {
                return TextLinePosition(
                    data: node.data,
                    range: NSRange(location: currentOffset, length: node.length),
                    yPos: currentYPosition,
                    height: node.height,
                    index: currentIndex
                )
            } else if currentYPosition > posY {
                currentNode = node.left
                currentOffset = (currentOffset - node.leftSubtreeOffset) + (node.left?.leftSubtreeOffset ?? 0)
                currentYPosition = (currentYPosition - node.leftSubtreeHeight) + (node.left?.leftSubtreeHeight ?? 0)
                currentIndex = (currentIndex - node.leftSubtreeCount) + (node.left?.leftSubtreeCount ?? 0)
            } else if node.leftSubtreeHeight < posY {
                currentNode = node.right
                currentOffset += node.length + (node.right?.leftSubtreeOffset ?? 0)
                currentYPosition += node.height + (node.right?.leftSubtreeHeight ?? 0)
                currentIndex += 1 + (node.right?.leftSubtreeCount ?? 0)
            } else {
                currentNode = nil
            }
        }

        return nil
    }

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
        assert(delta != 0 || deltaHeight != 0, "Delta must be non-0")
        guard let position = search(for: index) else {
            assertionFailure("No line found at index \(index)")
            return
        }
        if delta < 0 {
            assert(
                index - position.textPos > delta,
                "Delta too large. Deleting \(-delta) from line at position \(index) extends beyond the line's range."
            )
        }
        length += delta
        height += deltaHeight
        position.node.length += delta
        position.node.height += deltaHeight
        metaFixup(startingAt: position.node, delta: delta, deltaHeight: deltaHeight)
    }

    /// Deletes the line containing the given index.
    ///
    /// Will exit silently if a line could not be found for the given index, and throw an assertion error if the index
    /// is out of bounds.
    /// - Parameter index: The index to delete a line at.
    public func delete(lineAt index: Int) {
        assert(index >= 0 && index < self.length, "Invalid index, expected between 0 and \(self.length). Got \(index)")
        if count == 1 {
            removeAll()
            return
        }
        guard let node = search(for: index)?.node else { return }
        count -= 1
        length -= node.length
        height -= node.height
        deleteNode(node)
    }

    public func removeAll() {
        root = nil
        count = 0
        length = 0
        height = 0
    }

    /// Efficiently builds the tree from the given array of lines.
    /// - Parameter lines: The lines to use to build the tree.
    public func build(from lines: [BuildItem], estimatedLineHeight: CGFloat) {
        root = build(lines: lines, estimatedLineHeight: estimatedLineHeight, left: 0, right: lines.count, parent: nil).0
        count = lines.count
    }

    /// Recursively builds a subtree given an array of sorted lines, and a left and right indexes.
    /// - Parameters:
    ///   - lines: The lines to use to build the subtree.
    ///   - estimatedLineHeight: An estimated line height to add to the allocated nodes.
    ///   - left: The left index to use.
    ///   - right: The right index to use.
    ///   - parent: The parent of the subtree, `nil` if this is the root.
    /// - Returns: A node, if available, along with it's subtree's height and offset.
    private func build(
        lines: [BuildItem],
        estimatedLineHeight: CGFloat,
        left: Int,
        right: Int,
        parent: Node<Data>?
    ) -> (Node<Data>?, Int?, CGFloat?, Int) { // swiftlint:disable:this large_tuple
        guard left < right else { return (nil, nil, nil, 0) }
        let mid = left + (right - left)/2
        let node = Node(
            length: lines[mid].length,
            data: lines[mid].data,
            leftSubtreeOffset: 0,
            leftSubtreeHeight: 0,
            leftSubtreeCount: 0,
            height: estimatedLineHeight,
            color: .black
        )
        node.parent = parent

        let (left, leftOffset, leftHeight, leftCount) = build(
            lines: lines,
            estimatedLineHeight: estimatedLineHeight,
            left: left,
            right: mid,
            parent: node
        )
        let (right, rightOffset, rightHeight, rightCount) = build(
            lines: lines,
            estimatedLineHeight: estimatedLineHeight,
            left: mid + 1,
            right: right,
            parent: node
        )
        node.left = left
        node.right = right

        if node.left == nil && node.right == nil {
            node.color = .red
        }

        length += node.length
        height += node.height
        node.leftSubtreeOffset = leftOffset ?? 0
        node.leftSubtreeHeight = leftHeight ?? 0
        node.leftSubtreeCount = leftCount

        return (
            node,
            node.length + (leftOffset ?? 0) + (rightOffset ?? 0),
            node.height + (leftHeight ?? 0) + (rightHeight ?? 0),
            1 + leftCount + rightCount
        )
    }
}

private extension TextLineStorage {
    // MARK: - Search

    /// Searches for the given index. Returns a node and offset if found.
    /// - Parameter index: The index to look for in the document.
    /// - Returns: A tuple containing a node if it was found, and the offset of the node in the document.
    func search(for index: Int) -> NodePosition? {
        var currentNode = root
        var currentOffset: Int = root?.leftSubtreeOffset ?? 0
        var currentYPosition: CGFloat = root?.leftSubtreeHeight ?? 0
        var currentIndex: Int = root?.leftSubtreeCount ?? 0
        while let node = currentNode {
            // If index is in the range [currentOffset..<currentOffset + length) it's in the line
            if index >= currentOffset && index < currentOffset + node.length {
                return NodePosition(node: node, yPos: currentYPosition, textPos: currentOffset, index: currentIndex)
            } else if currentOffset > index {
                currentNode = node.left
                currentOffset = (currentOffset - node.leftSubtreeOffset) + (node.left?.leftSubtreeOffset ?? 0)
                currentYPosition = (currentYPosition - node.leftSubtreeHeight) + (node.left?.leftSubtreeHeight ?? 0)
                currentIndex = (currentIndex - node.leftSubtreeCount) + (node.left?.leftSubtreeCount ?? 0)
            } else if node.leftSubtreeOffset < index {
                currentNode = node.right
                currentOffset += node.length + (node.right?.leftSubtreeOffset ?? 0)
                currentYPosition += node.height + (node.right?.leftSubtreeHeight ?? 0)
                currentIndex += 1 + (node.right?.leftSubtreeCount ?? 0)
            } else {
                print(index, currentOffset, node.length)
                currentNode = nil
            }
        }
        return nil
    }

    // MARK: - Delete

    func deleteNode(_ node: Node<Data>) {
        if node.left != nil, let nodeRight = node.right {
            // Both children exist, replace with min of right
            let replacementNode = nodeRight.minimum()
            deleteNode(replacementNode)
            transplant(node, with: replacementNode)
            node.left?.parent = replacementNode
            node.right?.parent = replacementNode
            replacementNode.left = node.left
            replacementNode.right = node.right
            replacementNode.color = node.color
            replacementNode.leftSubtreeCount = node.leftSubtreeCount
            replacementNode.leftSubtreeHeight = node.leftSubtreeHeight
            replacementNode.leftSubtreeOffset = node.leftSubtreeOffset
            metaFixup(startingAt: replacementNode, delta: -node.length, deltaHeight: -node.height, nodeAction: .deleted)
        } else {
            // Either node's left or right is `nil`
            metaFixup(startingAt: node, delta: -node.length, deltaHeight: -node.height, nodeAction: .deleted)
            let replacementNode = node.left ?? node.right
            transplant(node, with: replacementNode)
            if node.color == .black {
                if replacementNode != nil && replacementNode?.color == .red {
                    replacementNode?.color = .black
                } else if let replacementNode {
                    deleteFixup(node: replacementNode)
                }
            }
        }
    }

    // MARK: - Fixup

    func insertFixup(node: Node<Data>) {
        metaFixup(startingAt: node, delta: node.length, deltaHeight: node.height, nodeAction: .inserted)

        var nextNode: Node<Data>? = node
        while var nodeX = nextNode, nodeX !== root, let nodeXParent = nodeX.parent, nodeXParent.color == .red {
            let nodeY = nodeXParent.sibling()
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

    // swiftlint:disable:next cyclomatic_complexity
    func deleteFixup(node: Node<Data>) {
        guard node.parent != nil, node.color == .black, var sibling = node.sibling() else { return }
        // Case 1: Sibling is red
        if sibling.color == .red {
            // Recolor
            sibling.color = .black
            if let nodeParent = node.parent {
                nodeParent.color = .red
                if isLeftChild(node) {
                    leftRotate(node: nodeParent)
                } else {
                    rightRotate(node: nodeParent)
                }
                if let newSibling = node.sibling() {
                    sibling = newSibling
                }
            }
        }

        // Case 2: Sibling is black with two black children
        if sibling.left?.color == .black && sibling.right?.color == .black {
            sibling.color = .red
            if let nodeParent = node.parent {
                deleteFixup(node: nodeParent)
            }
        } else {
            // Case 3: Sibling black with one black child
            if sibling.left?.color == .black || sibling.right?.color == .black {
                let isLeftBlack = sibling.left?.color == .black
                let siblingOtherChild = isLeftBlack ? sibling.right : sibling.left
                sibling.color = .red
                siblingOtherChild?.color = .black
                if isLeftBlack {
                    leftRotate(node: sibling)
                } else {
                    rightRotate(node: sibling)
                }
                if let newSibling = node.sibling() {
                    sibling = newSibling
                }
            }

            // Case 4: Sibling is black with red child
            if let nodeParent = node.parent {
                sibling.color = nodeParent.color
                nodeParent.color = .black
                if isLeftChild(node) {
                    sibling.right?.color = .black
                    leftRotate(node: nodeParent)
                } else {
                    sibling.left?.color = .black
                    rightRotate(node: nodeParent)
                }
                root?.color = .black
                return
            }
        }
        node.color = .black
    }

    /// Walk up the tree, updating any `leftSubtree` metadata.
    private func metaFixup(
        startingAt node: Node<Data>,
        delta: Int,
        deltaHeight: CGFloat,
        nodeAction: MetaFixupAction = .none
    ) {
        guard node.parent != nil else { return }
        var node: Node? = node
        while node != nil, node !== root {
            if isLeftChild(node!) {
                node?.parent?.leftSubtreeOffset += delta
                node?.parent?.leftSubtreeHeight += deltaHeight
                switch nodeAction {
                case .inserted:
                    node?.parent?.leftSubtreeCount += 1
                case .deleted:
                    node?.parent?.leftSubtreeCount -= 1
                case .none:
                    node = node?.parent
                    continue
                }
            }
            node = node?.parent
        }
    }

    func calculateSize(_ node: Node<Data>?) -> Int {
        guard let node else { return 0 }
        return node.length + node.leftSubtreeOffset + calculateSize(node.right)
    }
}

// MARK: - Rotations

private extension TextLineStorage {
    func rightRotate(node: Node<Data>) {
        rotate(node: node, left: false)
    }

    func leftRotate(node: Node<Data>) {
        rotate(node: node, left: true)
    }

    func rotate(node: Node<Data>, left: Bool) {
        var nodeY: Node<Data>?

        if left {
            nodeY = node.right
            nodeY?.leftSubtreeOffset += node.leftSubtreeOffset + node.length
            nodeY?.leftSubtreeHeight += node.leftSubtreeHeight + node.height
            nodeY?.leftSubtreeCount += node.leftSubtreeCount + 1
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
            node.leftSubtreeCount = (node.left == nil ? 1 : 0) + (node.left?.leftSubtreeCount ?? 0)
        }
        node.parent = nodeY
    }
}
