//
//  TextLineStorage+Node.swift
//  
//
//  Created by Khan Winter on 6/25/23.
//

import Foundation

extension TextLineStorage {
    func isRightChild(_ node: Node) -> Bool {
        node.parent?.right == node
    }

    func isLeftChild(_ node: Node) -> Bool {
        node.parent?.left == node
    }

    func sibling(_ node: Node) -> Node? {
        if isLeftChild(node) {
            return node.parent?.right
        } else {
            return node.parent?.left
        }
    }

    final class Node: Equatable {
        enum Color {
            case red
            case black
        }

        // The length of the text line
        var length: Int
        var id: UUID = UUID()
        var line: TextLine

        // The offset in characters of the entire left subtree
        var leftSubtreeOffset: Int
        var leftSubtreeHeight: CGFloat
        var height: CGFloat

        var left: Node?
        var right: Node?
        unowned var parent: Node?
        var color: Color

        init(
            length: Int,
            line: TextLine,
            leftSubtreeOffset: Int,
            leftSubtreeHeight: CGFloat,
            height: CGFloat,
            left: Node? = nil,
            right: Node? = nil,
            parent: Node? = nil,
            color: Color
        ) {
            self.length = length
            self.line = line
            self.leftSubtreeOffset = leftSubtreeOffset
            self.leftSubtreeHeight = leftSubtreeHeight
            self.height = height
            self.left = left
            self.right = right
            self.parent = parent
            self.color = color
        }

        static func == (lhs: Node, rhs: Node) -> Bool {
            lhs.id == rhs.id
        }

        func minimum() -> Node? {
            if let left {
                return left.minimum()
            } else {
                return self
            }
        }

        func maximum() -> Node? {
            if let right {
                return right.maximum()
            } else {
                return self
            }
        }

        func getSuccessor() -> Node? {
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
    }
}
