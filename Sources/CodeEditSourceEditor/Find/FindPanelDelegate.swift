//
//  FindPanelDelegate.swift
//  CodeEditSourceEditor
//
//  Created by Austin Condiff on 3/12/25.
//

import Foundation

protocol FindPanelDelegate: AnyObject {
    func findPanelOnSubmit()
    func findPanelOnDismiss()
    func findPanelDidUpdate(_ searchText: String)
    func findPanelDidUpdateMode(_ mode: FindPanelMode)
    func findPanelDidUpdateWrapAround(_ wrapAround: Bool)
    func findPanelDidUpdateMatchCase(_ matchCase: Bool)
    func findPanelDidUpdateReplaceText(_ text: String)
    func findPanelPrevButtonClicked()
    func findPanelNextButtonClicked()
    func findPanelReplaceButtonClicked()
    func findPanelReplaceAllButtonClicked()
    func findPanelUpdateMatchCount(_ count: Int)
    func findPanelClearEmphasis()
}
