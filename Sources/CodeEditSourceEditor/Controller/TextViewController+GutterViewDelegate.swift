//
//  TextViewController+GutterViewDelegate.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 4/17/25.
//

import Foundation

extension TextViewController: GutterViewDelegate {
    public func gutterViewWidthDidUpdate(newWidth: CGFloat) {
        gutterView?.frame.size.width = newWidth
        textView?.textInsets = textViewInsets
    }
}
