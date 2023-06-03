//
//  PthreadLock.swift
//  CodeEditTextView
//
//  Created by Khan Winter on 6/2/23.
//

import Foundation

/// A thread safe, atomic lock that wraps a `pthread_mutex_t`
struct PthreadLock {
    private var _lock: pthread_mutex_t

    /// Initializes the lock
    init() {
        _lock = .init()
        pthread_mutex_init(&_lock, nil)
    }

    /// Locks the lock, if the lock is already locked it will block the current thread until it unlocks.
    mutating func lock() {
        pthread_mutex_lock(&_lock)
    }

    /// Unlocks the lock.
    mutating func unlock() {
        pthread_mutex_unlock(&_lock)
    }
}
