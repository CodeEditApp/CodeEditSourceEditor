//
//  TreeSitterClientExecutor.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 5/30/24.
//

import Foundation

/// This class manages async/sync operations for the ``TreeSitterClient``.
///
/// To force all operations to happen synchronously (for example, during testing), initialize this object setting the
/// `forceSync` parameter to true.
package class TreeSitterClientExecutor {
    /// The error enum for ``TreeSitterClientExecutor``
    public enum Error: Swift.Error {
        /// Thrown when an operation was not able to be performed asynchronously.
        case syncUnavailable
    }

    /// The number of operations running or enqueued to run on the dispatch queue. This variable **must** only be
    /// changed from the main thread or race conditions are very likely.
    private var runningOperationCount = 0

    /// The number of times the object has been set up. Used to cancel async tasks if
    /// ``TreeSitterClient/setUp(textView:codeLanguage:)`` is called.
    private var setUpCount = 0

    /// Set to true to force all operations to happen synchronously. Useful for testing.
    private let forceSync: Bool

    /// The concurrent queue to perform operations on.
    private let operationQueue = DispatchQueue(
        label: "CodeEditSourceEditor.TreeSitter.EditQueue",
        qos: .userInteractive
    )

    /// Initialize an executor.
    /// - Parameter forceSync: Set to true to force all async operations to be performed synchronously. This will block
    ///                        the main thread until every operation has completed.
    init(forceSync: Bool = false) {
        self.forceSync = forceSync
    }

    package func incrementSetupCount() {
        setUpCount += 1
    }

    /// Performs the given operation asynchronously.
    ///
    /// All completion handlers passed to this function will be enqueued on the `operationQueue` dispatch queue,
    /// ensuring serial access to this class.
    ///
    /// This function will handle ensuring balanced increment/decrements are made to the `runningOperationCount` in
    /// a safe manner.
    ///
    /// - Note: While in debug mode, this method will throw an assertion failure if not called from the Main thread.
    /// - Parameter operation: The operation to perform
    package func performAsync(_ operation: @escaping () -> Void) {
        assertMain()

        guard !forceSync else {
            try? performSync(operation)
            return
        }

        runningOperationCount += 1
        let setUpCountCopy = setUpCount
        operationQueue.async { [weak self] in
            guard self != nil && self?.setUpCount == setUpCountCopy else { return }
            operation()
            DispatchQueue.main.async {
                self?.runningOperationCount -= 1
            }
        }
    }

    /// Attempts to perform a synchronous operation on the client.
    ///
    /// The operation will be dispatched synchronously to the `operationQueue`, this function will return once the
    /// operation is finished.
    ///
    /// - Note: While in debug mode, this method will throw an assertion failure if not called from the Main thread.
    /// - Parameter operation: The operation to perform synchronously.
    /// - Throws: Can throw an ``TreeSitterClient/Error/syncUnavailable`` error if it's determined that an async
    ///           operation is unsafe.
    package func performSync<T>(_ operation: @escaping () throws -> T) throws -> T {
        assertMain()

        guard runningOperationCount == 0 || forceSync else {
            throw Error.syncUnavailable
        }

        runningOperationCount += 1

        let returnValue: T
        if forceSync {
            returnValue = try operation()
        } else {
            returnValue = try operationQueue.sync {
                try operation()
            }
        }

        self.runningOperationCount -= 1

        return returnValue
    }

    /// Assert that the caller is calling from the main thread.
    private func assertMain() {
#if DEBUG
        if !Thread.isMainThread {
            assertionFailure("TreeSitterClient used from non-main queue. This will cause race conditions.")
        }
#endif
    }

    /// Executes a task on the main thread.
    /// If the caller is on the main thread already, executes it immediately. If not, it is queued
    /// asynchronously for the main queue.
    /// - Parameter task: The operation to execute.
    package func dispatchMain(_ operation: @escaping () -> Void) {
        if Thread.isMainThread {
            operation()
        } else {
            DispatchQueue.main.async {
                operation()
            }
        }
    }
}
