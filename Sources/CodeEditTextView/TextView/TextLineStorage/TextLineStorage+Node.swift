//
//  TextLineStorage+Node.swift
//  
//
//  Created by Khan Winter on 6/25/23.
//

import Foundation

extension TextLineStorage {
    func isRightChild(_ node: Node<Data>) -> Bool {
        node.parent?.right == node
    }

    func isLeftChild(_ node: Node<Data>) -> Bool {
        node.parent?.left == node
    }

    func sibling(_ node: Node<Data>) -> Node<Data>? {
        if isLeftChild(node) {
            return node.parent?.right
        } else {
            return node.parent?.left
        }
    }

    final class Node<Data: Identifiable>: Equatable {
        enum Color {
            case red
            case black
        }

        // The length of the text line
        var length: Int
        var data: Data

        // The offset in characters of the entire left subtree
        var leftSubtreeOffset: Int
        var leftSubtreeHeight: CGFloat
        var height: CGFloat

        var left: Node<Data>?
        var right: Node<Data>?
        unowned var parent: Node<Data>?
        var color: Color

        init(
            length: Int,
            data: Data,
            leftSubtreeOffset: Int,
            leftSubtreeHeight: CGFloat,
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
            self.height = height
            self.left = left
            self.right = right
            self.parent = parent
            self.color = color
        }

        static func == (lhs: Node, rhs: Node) -> Bool {
            lhs.data.id == rhs.data.id
        }

        func minimum() -> Node<Data>? {
            if let left {
                return left.minimum()
            } else {
                return self
            }
        }

        func maximum() -> Node<Data>? {
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
                while currentNode.parent?.right == currentNode {
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
