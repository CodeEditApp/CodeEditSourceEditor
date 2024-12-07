//
//  StyledRangeStoreRun.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 11/4/24.
//

/// Consumer-facing value type for the stored values in this container.
struct StyledRangeStoreRun: Equatable, Hashable {
    var length: Int
    var capture: CaptureName?
    var modifiers: CaptureModifierSet

    static func empty(length: Int) -> Self {
        StyledRangeStoreRun(length: length, capture: nil, modifiers: [])
    }

    var isEmpty: Bool {
        capture == nil && modifiers.isEmpty
    }

    mutating package func combineLowerPriority(_ other: borrowing StyledRangeStoreRun) {
        if self.capture == nil {
            self.capture = other.capture
        }
        self.modifiers.formUnion(other.modifiers)
    }

    mutating package func combineHigherPriority(_ other: borrowing StyledRangeStoreRun) {
        self.capture = other.capture ?? self.capture
        self.modifiers.formUnion(other.modifiers)
    }

    mutating package func subtractLength(_ other: borrowing StyledRangeStoreRun) {
        self.length -= other.length
    }
}

extension StyledRangeStoreRun: CustomDebugStringConvertible {
    var debugDescription: String {
        if isEmpty {
            "\(length) (empty)"
        } else {
            "\(length) (\(capture.debugDescription), \(modifiers.values.debugDescription))"
        }
    }
}
