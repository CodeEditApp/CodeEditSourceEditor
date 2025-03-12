//
//  FindTarget.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 3/10/25.
//

// This dependency is not ideal, maybe we could make this another protocol that the emphasize API conforms to similar
// to this one?
import CodeEditTextView

protocol FindTarget: AnyObject {
    var emphasizeAPI: EmphasizeAPI? { get }
    var text: String { get }

    var cursorPositions: [CursorPosition] { get }
    func setCursorPositions(_ positions: [CursorPosition])
    func updateCursorPosition()
}
