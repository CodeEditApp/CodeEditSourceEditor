//
//  TextViewController+FindPanelTarget.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 3/16/25.
//

import Foundation
import CodeEditTextView

extension TextViewController: FindPanelTarget {
    func findPanelWillShow(panelHeight: CGFloat) {
        scrollView.contentInsets.top += panelHeight
        gutterView.frame.origin.y = -scrollView.contentInsets.top
    }

    func findPanelWillHide(panelHeight: CGFloat) {
        scrollView.contentInsets.top -= panelHeight
        gutterView.frame.origin.y = -scrollView.contentInsets.top
    }

    func findPanelModeDidChange(to mode: FindPanelMode, panelHeight: CGFloat) {
        scrollView.contentInsets.top += mode == .replace ? panelHeight/2 : -panelHeight
        gutterView.frame.origin.y = -scrollView.contentInsets.top
    }

    var emphasisManager: EmphasisManager? {
        textView?.emphasisManager
    }
}
