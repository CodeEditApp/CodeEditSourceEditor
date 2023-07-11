//
//  STTextView+TextInterface.swift
//  
//
//  Created by Khan Winter on 1/26/23.
//

import AppKit
import STTextView
import TextStory
import TextFormation

extension STTextView: TextInterface {
    public var selectedRange: NSRange {
        get {
            return self.selectedRange()
        }
        set {
            guard let textContentStorage = textContentStorage else {
                return
            }
            if let textRange = NSTextRange(newValue, provider: textContentStorage) {
                self.setSelectedTextRange(textRange)
            }
        }
    }

    public var length: Int {
        textContentStorage?.length ?? 0
    }

    public func substring(from range: NSRange) -> String? {
        return textContentStorage?.substring(from: range)
    }

    /// Applies the mutation to the text view.
    /// - Parameter mutation: The mutation to apply.
    public func applyMutation(_ mutation: TextMutation) {
        registerUndo(mutation)
        applyMutationNoUndo(mutation)
    }

    fileprivate func registerUndo(_ mutation: TextMutation) {
        if let manager = undoManager as? CEUndoManager.DelegatedUndoManager {
            manager.registerMutation(mutation)
        }
    }

    public func applyMutationNoUndo(_ mutation: TextMutation) {
        textContentStorage?.performEditingTransaction {
            textContentStorage?.applyMutation(mutation)
        }

        let delegate = self.delegate
        self.delegate = nil
        textDidChange(nil)
        self.delegate = delegate
    }
}
