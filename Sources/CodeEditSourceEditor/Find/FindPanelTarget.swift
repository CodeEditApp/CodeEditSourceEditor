//
//  FindPanelTarget.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 3/10/25.
//

import Foundation
import CodeEditTextView

protocol FindPanelTarget: AnyObject {
    var emphasisManager: EmphasisManager? { get }
    var text: String { get }

    var cursorPositions: [CursorPosition] { get }
    func setCursorPositions(_ positions: [CursorPosition])
    func updateCursorPosition()

    func findPanelWillShow(panelHeight: CGFloat)
    func findPanelWillHide(panelHeight: CGFloat)
}
