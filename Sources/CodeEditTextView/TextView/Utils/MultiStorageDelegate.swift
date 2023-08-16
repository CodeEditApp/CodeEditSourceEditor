//
//  MultiStorageDelegate.swift
//  
//
//  Created by Khan Winter on 6/25/23.
//

import AppKit

class MultiStorageDelegate: NSObject, NSTextStorageDelegate {
    private var delegates = NSHashTable<NSTextStorageDelegate>.weakObjects()

    func addDelegate(_ delegate: NSTextStorageDelegate) {
        delegates.add(delegate)
    }

    func textStorage(
        _ textStorage: NSTextStorage,
        didProcessEditing editedMask: NSTextStorageEditActions,
        range editedRange: NSRange,
        changeInLength delta: Int
    ) {
        delegates.allObjects.forEach { delegate in
            delegate.textStorage?(textStorage, didProcessEditing: editedMask, range: editedRange, changeInLength: delta)
        }
    }

    func textStorage(
        _ textStorage: NSTextStorage,
        willProcessEditing editedMask: NSTextStorageEditActions,
        range editedRange: NSRange,
        changeInLength delta: Int
    ) {
        delegates.allObjects.forEach { delegate in
            delegate
                .textStorage?(textStorage, willProcessEditing: editedMask, range: editedRange, changeInLength: delta)
        }
    }
}
