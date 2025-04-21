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
        updateContentInsets()
    }

    func findPanelWillHide(panelHeight: CGFloat) {
        updateContentInsets()
    }

    var emphasisManager: EmphasisManager? {
        textView?.emphasisManager
    }
}
