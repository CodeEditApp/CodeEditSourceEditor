//
//  TextView+UndoRedo.swift
//  
//
//  Created by Khan Winter on 8/21/23.
//

import AppKit

extension TextView {
    override var undoManager: UndoManager? {
        _undoManager?.manager
    }

    @objc func undo(_ sender: AnyObject?) {
        if allowsUndo {
            undoManager?.undo()
        }
    }

    @objc func redo(_ sender: AnyObject?) {
        if allowsUndo {
            undoManager?.redo()
        }
    }

}
