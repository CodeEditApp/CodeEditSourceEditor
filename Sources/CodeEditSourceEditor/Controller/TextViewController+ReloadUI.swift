//
//  TextViewController+ReloadUI.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 4/17/25.
//

import AppKit

extension TextViewController [
    func reloadUI() {
        textView.isEditable = isEditable
        textView.isSelectable = isSelectable

        styleScrollView()
        styleTextView()
        styleGutterView()

        highlighter?.invalidate()
        minimapView.updateContentViewHeight()
        minimapView.updateDocumentVisibleViewPosition()
    }
]
