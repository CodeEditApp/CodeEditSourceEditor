//
//  TextView+Setup.swift
//  
//
//  Created by Khan Winter on 9/15/23.
//

import AppKit

extension TextView {
    internal func setUpLayoutManager(lineHeightMultiplier: CGFloat, wrapLines: Bool) -> TextLayoutManager {
        TextLayoutManager(
            textStorage: textStorage,
            lineHeightMultiplier: lineHeightMultiplier,
            wrapLines: wrapLines,
            textView: self,
            delegate: self
        )
    }

    internal func setUpSelectionManager() -> TextSelectionManager {
        TextSelectionManager(
            layoutManager: layoutManager,
            textStorage: textStorage,
            layoutView: self,
            delegate: self
        )
    }
}
