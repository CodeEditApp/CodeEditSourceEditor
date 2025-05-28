//
//  StyledRangeStoreRun.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 11/4/24.
//

protocol StyledRangeStoreElement: Equatable, Hashable {
    var isEmpty: Bool { get }
    func combineLowerPriority(_ other: Self?) -> Self
    func combineHigherPriority(_ other: Self?) -> Self
}

/// Consumer-facing value type for the stored values in this container.
struct StyledRangeStoreRun<Element: StyledRangeStoreElement>: Equatable, Hashable {
    var length: Int
    var value: Element?

    static func empty(length: Int) -> Self {
        StyledRangeStoreRun(length: length, value: nil)
    }

    var isEmpty: Bool {
        value?.isEmpty ?? true
    }

    mutating func combineLowerPriority(_ other: StyledRangeStoreRun) {
        value = value?.combineLowerPriority(other.value) ?? other.value
    }

    mutating func combineHigherPriority(_ other: StyledRangeStoreRun) {
        value = value?.combineHigherPriority(other.value) ?? other.value
    }

    mutating func subtractLength(_ other: borrowing StyledRangeStoreRun) {
        self.length -= other.length
    }
}

extension StyledRangeStoreRun: CustomDebugStringConvertible {
    var debugDescription: String {
        if let value = value as? CustomDebugStringConvertible {
            "\(length) (\(value.debugDescription))"
        } else {
            "\(length) (empty)"
        }
    }
}
