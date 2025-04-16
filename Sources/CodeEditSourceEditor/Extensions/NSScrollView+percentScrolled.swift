//
//  NSScrollView+percentScrolled.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 4/15/25.
//

import AppKit

extension NSScrollView {
    var documentMaxOriginY: CGFloat {
        let totalHeight = (documentView?.frame.height ?? 0.0) + contentInsets.top
        return totalHeight - (documentVisibleRect.height - contentInsets.top)
    }

    var percentScrolled: CGFloat {
        let currentYPos = documentVisibleRect.origin.y + contentInsets.top
        return currentYPos / documentMaxOriginY
    }
}
