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
            if let textRange = NSTextRange(newValue, provider: textContentStorage) {
                self.setSelectedRange(textRange)
            }
        }
    }

    public var length: Int {
        textContentStorage.length
    }

    public func substring(from range: NSRange) -> String? {
        return textContentStorage.substring(from: range)
    }

    public func applyMutation(_ mutation: TextStory.TextMutation) {
        if let manager = undoManager {
            let inverse = inverseMutation(for: mutation)

            manager.registerUndo(withTarget: self, handler: { (storable) in
                storable.applyMutation(inverse)
            })
        }

        textContentStorage.performEditingTransaction {
            textContentStorage.applyMutation(mutation)
        }

        didChangeText()
    }
}
