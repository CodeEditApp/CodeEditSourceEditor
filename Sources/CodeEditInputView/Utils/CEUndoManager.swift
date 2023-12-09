//
//  CEUndoManager.swift
//  CodeEditTextView
//
//  Created by Khan Winter on 7/8/23.
//

import AppKit
import TextStory

/// Maintains a history of edits applied to the editor and allows for undo/redo actions using those edits.
/// 
/// This object also groups edits into sequences that make for a better undo/redo editing experience such as:
/// - Breaking undo groups on newlines
/// - Grouping pasted text
///
/// If needed, the automatic undo grouping can be overridden using the `beginGrouping()` and `endGrouping()` methods.
public class CEUndoManager {
    /// An `UndoManager` subclass that forwards relevant actions to a `CEUndoManager`.
    /// Allows for objects like `TextView` to use the `UndoManager` API
    /// while CETV manages the undo/redo actions.
    public class DelegatedUndoManager: UndoManager {
        weak var parent: CEUndoManager?

        public override var canUndo: Bool { parent?.canUndo ?? false }
        public override var canRedo: Bool { parent?.canRedo ?? false }

        public func registerMutation(_ mutation: TextMutation) {
            parent?.registerMutation(mutation)
            removeAllActions()
        }

        public override func undo() {
            parent?.undo()
        }

        public override func redo() {
            parent?.redo()
        }

        public override func registerUndo(withTarget target: Any, selector: Selector, object anObject: Any?) {
            // no-op, but just in case to save resources:
            removeAllActions()
        }
    }

    /// Represents a group of mutations that should be treated as one mutation when undoing/redoing.
    private struct UndoGroup {
        var mutations: [Mutation]
    }

    /// A single undo mutation.
    private struct Mutation {
        var mutation: TextMutation
        var inverse: TextMutation
    }

    public let manager: DelegatedUndoManager
    private(set) public var isUndoing: Bool = false
    private(set) public var isRedoing: Bool = false

    public var canUndo: Bool {
        !undoStack.isEmpty
    }
    public var canRedo: Bool {
        !redoStack.isEmpty
    }

    /// A stack of operations that can be undone.
    private var undoStack: [UndoGroup] = []
    /// A stack of operations that can be redone.
    private var redoStack: [UndoGroup] = []

    private weak var textView: TextView?
    private(set) public var isGrouping: Bool = false
    /// True when the manager is ignoring mutations.
    private var isDisabled: Bool = false

    // MARK: - Init

    public init() {
        self.manager = DelegatedUndoManager()
        manager.parent = self
    }

    convenience init(textView: TextView) {
        self.init()
        self.textView = textView
    }

    // MARK: - Undo/Redo

    /// Performs an undo operation if there is one available.
    public func undo() {
        guard !isDisabled, let item = undoStack.popLast(), let textView else {
            return
        }
        isUndoing = true
        for mutation in item.mutations.reversed() {
            NotificationCenter.default.post(name: .NSUndoManagerWillUndoChange, object: self.manager)
            textView.insertText(mutation.inverse.string, replacementRange: mutation.inverse.range)
            NotificationCenter.default.post(name: .NSUndoManagerDidUndoChange, object: self.manager)
        }
        redoStack.append(item)
        isUndoing = false
    }

    /// Performs a redo operation if there is one available.
    public func redo() {
        guard !isDisabled, let item = redoStack.popLast(), let textView else {
            return
        }
        isRedoing = true
        for mutation in item.mutations {
            NotificationCenter.default.post(name: .NSUndoManagerWillRedoChange, object: self.manager)
            textView.insertText(mutation.mutation.string, replacementRange: mutation.mutation.range)
            NotificationCenter.default.post(name: .NSUndoManagerDidRedoChange, object: self.manager)
        }
        undoStack.append(item)
        isRedoing = false
    }

    /// Clears the undo/redo stacks.
    public func clearStack() {
        undoStack.removeAll()
        redoStack.removeAll()
    }

    // MARK: - Mutations

    /// Registers a mutation into the undo stack.
    ///
    /// Calling this method while the manager is in an undo/redo operation will result in a no-op.
    /// - Parameter mutation: The mutation to register for undo/redo
    public func registerMutation(_ mutation: TextMutation) {
        guard let textView,
              let textStorage = textView.textStorage,
              !isUndoing,
              !isRedoing else {
            return
        }
        let newMutation = Mutation(mutation: mutation, inverse: textStorage.inverseMutation(for: mutation))
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

    // MARK: - Grouping

    /// Groups all incoming mutations.
    public func beginGrouping() {
        isGrouping = true
    }

    /// Stops grouping all incoming mutations.
    public func endGrouping() {
        isGrouping = false
    }

    /// Determines whether or not two mutations should be grouped.
    ///
    /// Will break group if:
    /// - Last mutation is delete and new is insert, and vice versa *(insert and delete)*.
    /// - Last mutation was not whitespace, new is whitespace *(insert)*.
    /// - New mutation is a newline *(insert and delete)*.
    /// - New mutation is not sequential with the last one *(insert and delete)*.
    ///
    /// - Parameters:
    ///   - mutation: The current mutation.
    ///   - lastMutation: The last mutation applied to the document.
    /// - Returns: Whether or not the given mutations can be grouped.
    private func shouldContinueGroup(_ mutation: Mutation, lastMutation: Mutation) -> Bool {
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

            // Only attempt this check if the mutations are small enough.
            // If the last mutation was not whitespace, and the new one is, break the group.
            if lastMutation.mutation.string.count < 1024
                && mutation.mutation.string.count < 1024
                && !lastMutation.mutation.string.trimmingCharacters(in: .whitespaces).isEmpty
                && mutation.mutation.string.trimmingCharacters(in: .whitespaces).isEmpty {
                return false
            }

            return (
                lastMutation.mutation.range.max + 1 == mutation.mutation.range.location
                && mutation.mutation.string != "\n"
            )
        }
    }

    // MARK: - Disable

    /// Sets the undo manager to ignore incoming mutations until the matching `enable` method is called.
    /// Cannot be nested.
    public func disable() {
        isDisabled = true
    }

    /// Sets the undo manager to begin receiving incoming mutations after a call to `disable`
    /// Cannot be nested.
    public func enable() {
        isDisabled = false
    }
}
