//
//  Atomic.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 9/2/24.
//

import Foundation

/// A simple atomic value using `NSLock`.
@propertyWrapper
final package class Atomic<T> {
    private let lock: NSLock = .init()
    private var _wrappedValue: T

    package var wrappedValue: T {
        get {
            return lock.withLock { _wrappedValue }
        }
        set {
            lock.withLock { _wrappedValue = newValue }
        }
    }

    package init(wrappedValue: T) {
        self._wrappedValue = wrappedValue
    }
}
