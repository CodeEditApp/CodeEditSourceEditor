//
//  RangeStore.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 10/16/24.
//

import Foundation
import OrderedCollections

fileprivate extension Range<UInt32> {
    static func from(_ other: Range<Int>) -> Range<UInt32> {
        return UInt32(other.startIndex)..<UInt32(other.endIndex)
    }

    var generic: Range<Int> {
        return Int(startIndex)..<Int(endIndex)
    }

    func strictContains(_ other: Range<UInt32>) -> Bool {
        other.startIndex >= startIndex && other.endIndex <= endIndex
    }

    func subtract(_ other: Range<UInt32>) -> Range<UInt32> {
        assert(!strictContains(other), "Subtract cannot act on a range that is larger than the given range")
        if startIndex < other.startIndex {
            return startIndex..<other.startIndex
        } else {
            return other.endIndex..<endIndex
        }
    }
}

package final class RangeStore<Element> {
    /// Using UInt32 as we can halve the memory use of keys in the tree for the small cost of converting them
    /// in public calls.
    typealias Key = Range<UInt32>

    struct KeyValue {
        let key: Key
        let value: Element
    }

    private let order: Int
    private var root: Node

    init(order: Int = 4) {
        self.order = order
        self.root = Node(order: self.order)
    }

    func insert(value: Element, range: Range<Int>) {
        let key = Key.from(range)
        root.insert(value: value, range: key)
    }

    @discardableResult
    func delete(range: Range<Int>) -> Bool {
        let key = Key.from(range)
        return root.delete(range: key)
    }

//    func deleteRanges(overlapping range: Range<Int>) {
//        let key = Key.from(range)
//        let keyPairs = ranges(overlapping: range)
//        for pair in keyPairs {
//            root.delete(range: pair.key)
//            if !key.strictContains(pair.key) {
//                root.insert(value: pair.value, range: key.)
//            }
//        }
//    }

    func ranges(overlapping range: Range<Int>) -> [KeyValue] {
        let key = Key.from(range)
        return root.findRanges(overlapping: key)
    }
}
