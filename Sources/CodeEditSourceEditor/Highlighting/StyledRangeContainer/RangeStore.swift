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
    
    /// Determines if the given range is entirely contained by this range.
    /// - Parameter other: The range to compare.
    /// - Returns: If the range's indices are equal to or inside this range's indices, returns true.
    func strictContains(_ other: Range<UInt32>) -> Bool {
        other.startIndex >= startIndex && other.endIndex <= endIndex
    }
}

/// A `RangeStore` is a generic, B-tree-backed data structure that stores key-value pairs where the keys are ranges.
///
/// This class allows efficient insertion, deletion, and querying of ranges, offering the flexibility to clear entire ranges
/// of values or remove single values. The underlying B-tree gives logarithmic time complexity for most operations.
///
/// - Note: The internal keys are stored as `Range<UInt32>` to optimize memory usage, and are converted from `Range<Int>`
///   when interacting with public
///
/// ```swift
/// let store = RangeStore<String>()
/// store.insert(value: "A", range: 1..<5)
/// store.delete(overlapping: 3..<4) // Clears part of a range.
/// let results = store.ranges(overlapping: 1..<6)
/// ```

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

    /// Initialize the store.
    /// - Parameter order: The order of the internal B-tree. Defaults to `4`.
    init(order: Int = 4) {
        self.order = order
        self.root = Node(order: self.order)
    }

    /// Insert a key-value pair into the store.
    /// - Parameters:
    ///   - value: The value to insert.
    ///   - range: The range to insert the value at.
    func insert(value: Element, range: Range<Int>) {
        let key = Key.from(range)
        root.insert(value: value, range: key)
    }

    /// Delete a range from the store.
    /// The range must match exactly with a range in the store, or it will not be deleted.
    /// See ``delete(overlapping:)`` for deleting unknown ranges.
    /// - Parameter range: The range to remove.
    /// - Returns: Whether or not a value was removed from the store.
    @discardableResult
    func delete(range: Range<Int>) -> Bool {
        let key = Key.from(range)
        return root.delete(range: key)
    }

    /// Clears a range and all associated values.
    ///
    /// This is different from `delete`, which deletes a single already-known range from the store. This method removes
    /// a range entirely, trimming ranges to effectively clear a range of values.
    ///
    /// ```
    /// 1  2  3  4  5  6  # Indices
    /// |-----|  |-----|  # Stored Ranges
    ///
    /// - Call `delete` 3..<5
    ///
    /// 1  2  3  4  5  6 # Indices
    /// |--|        |--| # Stored Ranges
    /// ```
    ///
    /// - Complexity: `O(n)` worst case, `O(m log n)` for small ranges where `m` is the number of results returned.
    /// - Parameter range: The range to clear.
    func delete(overlapping range: Range<Int>) {
        let key = Key.from(range)
        let keySet = IndexSet(integersIn: key.range)

        let keyPairs = root.findRanges(overlapping: key)
        for pair in keyPairs {
            root.delete(range: pair.key)

            // Re-Insert any ranges that overlapped with the key but weren't encapsulated.
            if !key.strictContains(pair.key) {
                let remainingSet = IndexSet(integersIn: pair.key.range).subtracting(keySet)
                for range in remainingSet.rangeView {
                    let newKey = Key.from(range)
                    root.insert(value: pair.value, range: newKey)
                }
            }
        }
    }

    /// Search for all ranges overlapping the given range.
    /// ```
    /// 1  2  3  4  5  6  # Indices
    /// |-----|  |-----|  # Stored Ranges
    ///
    ///  - Call `ranges(overlapping:)` 1..<5
    ///  - Returns: [1..<4, 4..<7]
    /// ```
    /// - Complexity: `O(n)` worst case, `O(m log n)` for small ranges where `m` is the number of results returned.
    /// - Parameter range: The range to search.
    /// - Returns: All key-value pairs that overlap the given range.
    func ranges(overlapping range: Range<Int>) -> [(key: Range<Int>, value: Element)] {
        let key = Key.from(range)
        return root.findRanges(overlapping: key).map { keyValue in
            (keyValue.key.generic, keyValue.value)
        }
    }
}
