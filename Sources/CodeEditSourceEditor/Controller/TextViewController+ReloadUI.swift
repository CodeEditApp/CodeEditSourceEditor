//
//  TextViewController+ReloadUI.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 4/17/25.
//

import AppKit

extension TextViewController {
    func reloadUI() {
        textView.isEditable = isEditable
        textView.isSelectable = isSelectable

        styleScrollView()
        styleTextView()
        styleGutterView()

        highlighter?.invalidate()
        minimapView.updateContentViewHeight()
        minimapView.updateDocumentVisibleViewPosition()
        
        // Update reformatting guide position
        if let guideView = textView.subviews.first(where: { $0 is ReformattingGuideView }) as? ReformattingGuideView {
            guideView.updatePosition(in: textView)
        }
    }
}
