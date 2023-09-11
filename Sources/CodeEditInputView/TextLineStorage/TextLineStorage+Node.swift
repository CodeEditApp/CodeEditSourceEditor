//
//  TextLineStorage+Node.swift
//  
//
//  Created by Khan Winter on 6/25/23.
//

import Foundation

extension TextLineStorage {
    func isRightChild(_ node: Node<Data>) -> Bool {
        node.parent?.right === node
    }

    func isLeftChild(_ node: Node<Data>) -> Bool {
        node.parent?.left === node
    }

    /// Transplants a node with another node.
    ///
    /// ```
    ///         [a]
    ///     [u]_/ \_[b]
    /// [c]_/ \_[v]
    ///
    /// call: transplant(u, v)
    ///
    ///         [a]
    ///     [v]_/ \_[b]
    /// [c]_/
    ///
    /// ```
    /// - Note: Leaves the task of updating tree metadata to the caller.
    /// - Parameters:
    ///   - nodeU: The node to replace.
    ///   - nodeV: The node to insert in place of `nodeU`
    func transplant(_ nodeU: Node<Data>, with nodeV: Node<Data>?) {
        if nodeU.parent == nil {
            root = nodeV
        } else if isLeftChild(nodeU) {
            nodeU.parent?.left = nodeV
        } else {
            nodeU.parent?.right = nodeV
        }
        nodeV?.parent = nodeU.parent
    }

    final class Node<Data: Identifiable> {
        enum Color {
            case red
            case black
        }

        // The length of the text line
        var length: Int
        // The height of this text line
        var height: CGFloat
        var data: Data

        // The offset in characters of the entire left subtree
        var leftSubtreeOffset: Int
        // The sum of the height of the nodes in the left subtree
        var leftSubtreeHeight: CGFloat
        // The number of nodes in the left subtree
        var leftSubtreeCount: Int

        var left: Node<Data>?
        var right: Node<Data>?
        unowned var parent: Node<Data>?
        var color: Color

        init(
            length: Int,
            data: Data,
            leftSubtreeOffset: Int,
            leftSubtreeHeight: CGFloat,
            leftSubtreeCount: Int,
            height: CGFloat,
            left: Node<Data>? = nil,
            right: Node<Data>? = nil,
            parent: Node<Data>? = nil,
            color: Color
        ) {
            self.length = length
            self.data = data
            self.leftSubtreeOffset = leftSubtreeOffset
            self.leftSubtreeHeight = leftSubtreeHeight
            self.leftSubtreeCount = leftSubtreeCount
            self.height = height
            self.left = left
            self.right = right
            self.parent = parent
            self.color = color
        }

        func sibling() -> Node<Data>? {
            if parent?.left === self {
                return parent?.right
            } else {
                return parent?.left
            }
        }

        func minimum() -> Node<Data> {
            if let left {
                return left.minimum()
            } else {
                return self
            }
        }

        func maximum() -> Node<Data> {
            if let right {
                return right.maximum()
            } else {
                return self
            }
        }

        func getSuccessor() -> Node<Data>? {
            // If node has right child: successor is the min of this right tree
            if let right {
                return right.minimum()
            } else {
                // Else go upward until node is a left child
                var currentNode = self
                var parent = currentNode.parent
                while currentNode.parent?.right === currentNode {
                    if let parent = parent {
                        currentNode = parent
                    }
                    parent = currentNode.parent
                }
                return parent
            }
        }

        deinit {
            left = nil
            right = nil
            parent = nil
        }
    }
}
