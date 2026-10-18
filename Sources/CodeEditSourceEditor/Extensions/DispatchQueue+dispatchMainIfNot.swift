//
//  DispatchQueue+dispatchMainIfNot.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 9/2/24.
//

import Foundation

/// Helper methods for dispatching on the main queue only if the calling thread is not already the main queue.

extension DispatchQueue {
    /// Executes the work item on the main thread, dispatching asynchronously if the thread is not the main thread.
    /// - Parameter item: The work item to execute on the main thread.
    static func dispatchMainIfNot(_ item: @escaping () -> Void) {
        if Thread.isMainThread {
            item()
        } else {
            DispatchQueue.main.async {
                item()
            }
        }
    }
}
