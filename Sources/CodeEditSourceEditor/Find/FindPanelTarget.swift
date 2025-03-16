//
//  FindPanelTarget.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 3/10/25.
//

import Foundation

// This dependency is not ideal, maybe we could make this another protocol that the emphasize API conforms to similar
// to this one?
import CodeEditTextView

protocol FindPanelTarget: AnyObject {
    var emphasizeAPI: EmphasizeAPI? { get }
    var text: String { get }

    var cursorPositions: [CursorPosition] { get }
    func setCursorPositions(_ positions: [CursorPosition])
    func updateCursorPosition()

    func findPanelWillShow(panelHeight: CGFloat)
    func findPanelWillHide(panelHeight: CGFloat)
}
