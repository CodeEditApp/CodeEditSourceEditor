//
//  RangeStore+Node.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 10/16/24.
//

extension RangeStore {
    final class Node {
        let order: Int
        var keys: [KeyValue]
        var children: [Node]
        var maxContainingEndpoint: UInt32

        var isLeaf: Bool { children.isEmpty }

        init(order: Int) {
            self.order = order
            self.keys = []
            self.children = []
            self.maxContainingEndpoint = 0

            self.keys.reserveCapacity(order - 1)
            self.children.reserveCapacity(order)
        }

        func max() -> KeyValue? {
            var node = self
            while !node.isLeaf {
                node = node.children[node.children.count - 1]
            }
            return node.keys.last
        }

        func min() -> KeyValue? {
            var node = self
            while !node.isLeaf {
                node = node.children[0]
            }
            return node.keys.first
        }

        // MARK: - Insert

        @discardableResult
        func insert(value: Element, range: Key) -> (promotedKey: KeyValue?, newNode: Node?) {
            if isLeaf {
                // Insert in order
                let newKeyValue = KeyValue(key: range, value: value)
                let insertionIndex = keys.firstIndex(where: { $0.key.lowerBound > range.lowerBound }) ?? keys.count
                keys.insert(newKeyValue, at: insertionIndex)

                // Update maxContainingEndpoint going up
                maxContainingEndpoint = Swift.max(maxContainingEndpoint, range.upperBound)

                // Check if the node is overfull and needs to be split
                if keys.count >= keys.capacity {
                    return split()
                }
            } else {
                // Find the correct child to insert into
                let childIndex = keys.firstIndex(where: { $0.key.lowerBound > range.lowerBound }) ?? keys.count
                let (promotedKey, newChild) = children[childIndex].insert(value: value, range: range)

                // If a child was split, insert the promoted key into the current node
                if let promotedKey = promotedKey {
                    keys.insert(promotedKey, at: childIndex)
                    if let newChild = newChild {
                        children.insert(newChild, at: childIndex + 1)
                    }

                    // Check if the node needs to be split
                    if keys.count >= keys.capacity {
                        return split()
                    }
                }
            }

            return (nil, nil)
        }

        /// Split a node in half, returning the new node and the key to promote to the next level.
        private func split() -> (promotedKey: KeyValue, newNode: Node) {
            let middleIndex = keys.count / 2
            let promotedKey = keys[middleIndex]

            let newNode = Node(order: self.order)
            newNode.keys.append(contentsOf: keys[(middleIndex + 1)...])
            keys.removeSubrange(middleIndex...)

            if !isLeaf {
                newNode.children.append(contentsOf: children[(middleIndex + 1)...])
                children.removeSubrange((middleIndex + 1)...)
            }

            newNode.maxContainingEndpoint = newNode.keys.map { $0.key.upperBound }.max() ?? 0
            self.maxContainingEndpoint = self.keys.map { $0.key.upperBound }.max() ?? 0

            return (promotedKey, newNode)
        }

        // MARK: - Delete

        /// Delete the given key from the tree. Assumes the key exists exactly
        /// - Parameter range: The range to delete.
        @discardableResult
        func delete(range: Key) -> Bool {
            if let keyIndex = keys.firstIndex(where: { $0.key == range }) {
                if isLeaf {
                    keys.remove(at: keyIndex)
                    return true
                } else {
                    deleteNonLeaf(keyIndex: keyIndex, range: range)
                    return true
                }
            } else if !isLeaf {
                // Recursively delete from the appropriate child
                let childIndex = keys.firstIndex(where: { $0.key.lowerBound > range.lowerBound }) ?? keys.count
                let child = children[childIndex]

                // Ensure the child has enough keys to allow deletion
                if child.keys.count < order {
                    fillChild(at: childIndex)
                }

                // Recursive deletion
                return children[childIndex].delete(range: range)
            }

            // Key not found
            return false
        }

        /// Delete a key from a non-leaf node. Replacing the key with the next or last key in the tree.
        private func deleteNonLeaf(keyIndex: Int, range: Key) {
            // Non-leaf node: replace the key with a predecessor or successor
            let predecessorNode = children[keyIndex]
            let successorNode = children[keyIndex + 1]

            if predecessorNode.keys.count >= order {
                if let predecessor = predecessorNode.max() {
                    keys[keyIndex] = predecessor
                    predecessorNode.delete(range: predecessor.key)
                }
            } else if successorNode.keys.count >= order {
                if let successor = successorNode.min() {
                    keys[keyIndex] = successor
                    successorNode.delete(range: successor.key)
                }
            } else {
                // Merge the key and two children, then delete recursively
                mergeChild(at: keyIndex)
                children[keyIndex].delete(range: range)
            }
        }

        /// Ensure the child meets the invariants of a B-Tree.
        /// - Parameter index: The index of the child to update.
        private func fillChild(at index: Int) {
            if index > 0 && children[index - 1].keys.count > order - 1 {
                borrowFromPrev(at: index)
            } else if index < keys.count && children[index + 1].keys.count > order - 1 {
                borrowFromNext(at: index)
            } else {
                // Merge with a sibling
                if index > 0 {
                    mergeChild(at: index - 1)
                } else {
                    mergeChild(at: index)
                }
            }
        }

        /// Borrow a key from left sibling
        private func borrowFromPrev(at index: Int) {
            let child = children[index]
            let leftSibling = children[index - 1]
            child.keys.insert(keys[index - 1], at: 0)
            keys[index - 1] = leftSibling.keys.removeLast()

            if !leftSibling.isLeaf {
                child.children.insert(leftSibling.children.removeLast(), at: 0)
            }

            child.maxContainingEndpoint = child.keys.map { $0.key.upperBound }.max() ?? 0
            leftSibling.maxContainingEndpoint = leftSibling.keys.map { $0.key.upperBound }.max() ?? 0
        }

        /// Borrow a key from the right sibling
        private func borrowFromNext(at index: Int) {
            let child = children[index]
            let rightSibling = children[index + 1]
            child.keys.append(keys[index])
            keys[index] = rightSibling.keys.removeFirst()

            if !rightSibling.isLeaf {
                child.children.append(rightSibling.children.removeFirst())
            }

            child.maxContainingEndpoint = child.keys.map { $0.key.upperBound }.max() ?? 0
            rightSibling.maxContainingEndpoint = rightSibling.keys.map { $0.key.upperBound }.max() ?? 0
        }

        /// Merge the child at 'index' with the next sibling
        private func mergeChild(at index: Int) {
            let child = children[index]
            let sibling = children[index + 1]
            child.keys.append(keys.remove(at: index))
            child.keys.append(contentsOf: sibling.keys)
            if !sibling.isLeaf {
                child.children.append(contentsOf: sibling.children)
            }

            children.remove(at: index + 1)
            child.maxContainingEndpoint = child.keys.map { $0.key.upperBound }.max() ?? 0
        }

        // MARK: - Search

        /// Searches the node and it's children for any overlapping ranges.
        /// - Parameter range: The range to query
        /// - Returns: All (key,value) pairs overlapping the given key.
        func findRanges(overlapping range: Key) -> [KeyValue] {
            var overlappingRanges: [KeyValue] = []

            var idx = 0
            while idx < keys.count && keys[idx].key.lowerBound < range.upperBound {
                idx += 1

                if keys[idx - 1].key.overlaps(range) {
                    overlappingRanges.append(keys[idx - 1])
                }
            }

            if !isLeaf {
                for childIdx in 0..<idx where children[childIdx].maxContainingEndpoint >= range.lowerBound {
                    overlappingRanges.append(contentsOf: children[childIdx].findRanges(overlapping: range))
                }

                if idx < children.count {
                    if children[idx].maxContainingEndpoint >= range.lowerBound {
                        overlappingRanges.append(contentsOf: children[idx].findRanges(overlapping: range))
                    }
                }
            }

            return overlappingRanges
        }
    }
}
