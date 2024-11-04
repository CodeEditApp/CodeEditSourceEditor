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
    var modifiers: Set<CaptureModifiers>

    static func empty(length: Int) -> Self {
        HighlightedRun(length: length, capture: nil, modifiers: [])
    }

    mutating func combineLowerPriority(_ other: borrowing HighlightedRun) {
        if self.capture == nil {
            self.capture = other.capture
        }
        self.modifiers.formUnion(other.modifiers)
    }

    mutating func subtractLength(_ other: borrowing HighlightedRun) {
        self.length -= other.length
    }
}
