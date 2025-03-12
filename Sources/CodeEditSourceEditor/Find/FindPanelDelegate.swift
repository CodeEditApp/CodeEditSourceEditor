//
//  FindPanelDelegate.swift
//  CodeEditSourceEditor
//
//  Created by Austin Condiff on 3/12/25.
//

import Foundation

protocol FindPanelDelegate: AnyObject {
    func findPanelOnSubmit()
    func findPanelOnCancel()
    func findPanelDidUpdate(_ searchText: String)
    func findPanelPrevButtonClicked()
    func findPanelNextButtonClicked()
    func findPanelUpdateMatchCount(_ count: Int)
    func findPanelClearEmphasis()
}
