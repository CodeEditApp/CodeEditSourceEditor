//
//  Atomic.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 9/2/24.
//

import Foundation

/// A simple atomic counter using `NSLock`.
final package class AtomicCounter {
    private let lock: NSLock = .init()
    private var _value: Int = 0

    init(value: Int) {
        self._value = value
    }

    func increment() -> Int {
        lock.withLock {
            _value += 1
            return _value
        }
    }

    func value() -> Int {
        lock.withLock { _value }
    }
}
