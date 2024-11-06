//
//  HighlightedRun.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 11/4/24.
//

/// Consumer-facing value type for the stored values in this container.
struct HighlightedRun: Equatable, Hashable {
    var length: Int
    var capture: CaptureName?
    var modifiers: CaptureModifierSet

    static func empty(length: Int) -> Self {
        HighlightedRun(length: length, capture: nil, modifiers: [])
    }

    var isEmpty: Bool {
        capture == nil && modifiers.isEmpty
    }

    mutating func combineLowerPriority(_ other: borrowing HighlightedRun) {
        if self.capture == nil {
            self.capture = other.capture
        }
        self.modifiers.formUnion(other.modifiers)
    }

    mutating func combineHigherPriority(_ other: borrowing HighlightedRun) {
        self.capture = other.capture ?? self.capture
        self.modifiers.formUnion(other.modifiers)
    }

    mutating func subtractLength(_ other: borrowing HighlightedRun) {
        self.length -= other.length
    }
}

extension HighlightedRun: CustomDebugStringConvertible {
    var debugDescription: String {
        if isEmpty {
            "\(length) (empty)"
        } else {
            "\(length) (\(capture.debugDescription), \(modifiers.values.debugDescription))"
        }
    }
}
