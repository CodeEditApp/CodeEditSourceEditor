//
//  TreeSitterExecutor.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 9/2/24.
//

import Foundation

/// A class for managing
package class TreeSitterExecutor {
    enum Priority: Comparable {
        case access
        case edit
        case reset
        case all
    }

    private struct QueueItem {
        let task: (Task<Void, Never>)?
        let id: UUID
        let priority: Priority
    }

    private let lock = NSLock()
    private var queuedTasks: [QueueItem] = []

    enum Error: Swift.Error {
        case syncUnavailable
    }

    func execSync<T>(_ operation: () -> T) -> Result<T, Error> {
        guard let queueItemID = addSyncTask() else {
            return .failure(Error.syncUnavailable)
        }
        print("Execing sync \(queueItemID)")
        let returnVal = operation() // Execute outside critical area.
        print("Finished sync \(queueItemID)")
        // Critical area, modifying the queue.
        lock.withLock {
            queuedTasks.removeAll(where: { $0.id == queueItemID })
        }
        return .success(returnVal)
    }

    private func addSyncTask() -> UUID? {
        lock.lock()
        defer { lock.unlock() }
        guard queuedTasks.isEmpty else {
            return nil
        }
        let id = UUID()
        queuedTasks.append(QueueItem(task: nil, id: id, priority: .all))
        return id
    }

    func execAsync(priority: Priority = .access, operation: @escaping () -> Void, onCancel: @escaping () -> Void) {
        // Critical area, modifying the queue
        lock.lock()
        defer { lock.unlock() }
        let id = UUID()
        print("queuing task \(id)")
        let task = Task {
            while self.lock.withLock({ !canTaskExec(id: id, priority: priority) }) {
                await Task.yield()
                guard !Task.isCancelled else {
                    removeTask(id)
                    onCancel()
                    return
                }
            }

            guard !Task.isCancelled else {
                removeTask(id)
                onCancel()
                return
            }

            print("Execing task \(id)")
            operation()
            print("Finished task \(id)")

            removeTask(id)
        }
        queuedTasks.append(QueueItem(task: task, id: id, priority: priority))
    }

    private func removeTask(_ id: UUID) {
        self.lock.withLock {
            self.queuedTasks.removeAll(where: { $0.id == id })
            if self.queuedTasks.isEmpty {
                print("==== Queue Empty ====")
            }
        }
    }

    /// Allow concurrent ``TreeSitterExecutor/Priority/access`` operations to run.
    private func canTaskExec(id: UUID, priority: Priority) -> Bool {
        if priority != .access {
            return queuedTasks.first?.id == id
        }

        for task in queuedTasks {
            if task.priority != .access {
                return false
            } else {
                return task.id == id
            }
        }
        assertionFailure("Task asking if it can exec but it's not in the queue. Cancelling the task")
        return false
    }

    func cancelAll(below priority: Priority, _ completion: () -> Void) {
        lock.withLock {
            print("Cancelling all below: \(priority)")
            queuedTasks.forEach { item in
                if item.priority < priority && !(item.task?.isCancelled ?? true) {
                    print("Cancelling: \(item.id)")
                    item.task?.cancel()
                }
            }
        }
        completion()
    }

    deinit {
        lock.withLock {
            queuedTasks.forEach { item in
                item.task?.cancel()
            }
        }
    }
}
