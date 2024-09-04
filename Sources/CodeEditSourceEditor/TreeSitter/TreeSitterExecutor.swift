//
//  TreeSitterExecutor.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 9/2/24.
//

import Foundation

/// A class for managing
final package class TreeSitterExecutor {
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

    @discardableResult
    func execSync<T>(_ operation: () -> T) -> Result<T, Error> {
        guard let queueItemID = addSyncTask() else {
            return .failure(Error.syncUnavailable)
        }
        let returnVal = operation() // Execute outside critical area.
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
        let task = Task(priority: .userInitiated) { // This executes outside the lock's control.
            while self.lock.withLock({ !canTaskExec(id: id, priority: priority) }) {
                // Instead of yielding, sleeping frees up the CPU due to time off the CPU and less lock contention
                // lower than 1ms starts causing lock contention, much higher reduces responsiveness with diminishing
                // returns on CPU efficiency.
                try? await Task.sleep(for: .milliseconds(1))
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

            operation()

            if Task.isCancelled {
                onCancel()
            }

            removeTask(id)
        }
        queuedTasks.append(QueueItem(task: task, id: id, priority: priority))
    }

    private func removeTask(_ id: UUID) {
        self.lock.withLock {
            self.queuedTasks.removeAll(where: { $0.id == id })
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
        assertionFailure("Task asking if it can exec but it's not in the queue.")
        return false
    }

    func cancelAll(below priority: Priority) {
        lock.withLock {
            queuedTasks.forEach { item in
                if item.priority < priority && !(item.task?.isCancelled ?? true) {
                    item.task?.cancel()
                }
            }
        }
    }

    deinit {
        lock.withLock {
            queuedTasks.forEach { item in
                item.task?.cancel()
            }
        }
    }
}
