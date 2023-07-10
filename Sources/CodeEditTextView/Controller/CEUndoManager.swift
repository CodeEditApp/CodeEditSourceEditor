//
//  CEUndoManager.swift
//  CodeEditTextView
//
//  Created by Khan Winter on 7/8/23.
//

import STTextView
import AppKit
import TextStory

class CEUndoManager {
    class DelegatedUndoManager: UndoManager {
        weak var parent: CEUndoManager?

        override var canUndo: Bool { parent?.canUndo ?? false }
        override var canRedo: Bool { parent?.canRedo ?? false }

        func registerMutation(_ mutation: TextMutation) {
            parent?.registerMutation(mutation)
            removeAllActions()
        }

        override func undo() {
            parent?.undo()
        }

        override func redo() {
            parent?.redo()
        }

        override func registerUndo(withTarget target: Any, selector: Selector, object anObject: Any?) {
            super.registerUndo(withTarget: target, selector: selector, object: anObject)
            removeAllActions()
        }
    }

    private struct UndoGroup {
        struct Mutation {
            var mutation: TextMutation
            var inverse: TextMutation
        }

        var mutations: [Mutation]
    }

    public let manager: DelegatedUndoManager
    public var isUndoing: Bool = false
    public var isRedoing: Bool = false
    var canUndo: Bool {
        !undoStack.isEmpty
    }
    var canRedo: Bool {
        !redoStack.isEmpty
    }

    private var undoStack: [UndoGroup] = []
    private var redoStack: [UndoGroup] = []

    private unowned let textView: STTextView
    private(set) var isGrouping: Bool = false

    init(textView: STTextView) {
        self.textView = textView
        self.manager = DelegatedUndoManager()
        manager.parent = self
    }

    func undo() {
        guard let item = undoStack.popLast() else {
            return
        }
        isUndoing = true
        for mutation in item.mutations.reversed() {
            textView.applyMutationNoUndo(mutation.inverse)
        }
        redoStack.append(item)
        isUndoing = false
    }

    func redo() {
        guard let item = redoStack.popLast() else {
            return
        }
        isRedoing = true
        for mutation in item.mutations {
            textView.applyMutationNoUndo(mutation.mutation)
        }
        undoStack.append(item)
        isRedoing = false
    }

    ///
    /// - Parameter mutation: The mutation to register for undo/redo
    func registerMutation(_ mutation: TextMutation) {
        if (mutation.range.length == 0 && mutation.string.isEmpty) || isUndoing || isRedoing { return }
        let newMutation = UndoGroup.Mutation(mutation: mutation, inverse: textView.inverseMutation(for: mutation))
        if !undoStack.isEmpty, let lastMutation = undoStack.last?.mutations.last {
            if isGrouping || shouldContinueGroup(newMutation, lastMutation: lastMutation) {
                undoStack[undoStack.count - 1].mutations.append(newMutation)
            } else {
                undoStack.append(UndoGroup(mutations: [newMutation]))
            }
        } else {
            undoStack.append(
                UndoGroup(mutations: [newMutation])
            )
        }

        redoStack.removeAll()
    }

    /// Groups all incoming mutations.
    public func beginGrouping() {
        isGrouping = true
    }

    /// Stops grouping all incoming mutations.
    public func endGrouping() {
        isGrouping = false
    }

    private func shouldContinueGroup(_ mutation: UndoGroup.Mutation, lastMutation: UndoGroup.Mutation) -> Bool {
        // End group if:
        // - deleting:
        //     - deleted text is not contiguous
        // - inserting:
        //     - inserted text is not contiguous
        //     - OR inserted text is whitespace and last mutation was not (and vice versa)
        // If last mutation was delete & new is insert or vice versa, split group
        if (mutation.mutation.range.length > 0 && lastMutation.mutation.range.length == 0)
            || (mutation.mutation.range.length == 0 && lastMutation.mutation.range.length > 0) {
            return false
        }

        if mutation.mutation.string.isEmpty {
            // Deleting
            return (
                lastMutation.mutation.range.location == mutation.mutation.range.max
                && mutation.inverse.string != "\n"
            )
        } else {
            // Inserting
            return (
                lastMutation.mutation.range.max + 1 == mutation.mutation.range.location
                && mutation.mutation.string != "\n"
            )
        }
    }
}
