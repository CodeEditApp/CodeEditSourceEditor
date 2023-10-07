//
//  TextView+Setup.swift
//  
//
//  Created by Khan Winter on 9/15/23.
//

import AppKit

extension TextView {
    internal func setUpLayoutManager() -> TextLayoutManager {
        TextLayoutManager(
            textStorage: textStorage,
            typingAttributes: [
                .font: font
            ],
            lineHeightMultiplier: lineHeight,
            wrapLines: wrapLines,
            textView: self, // TODO: This is an odd syntax... consider reworking this
            delegate: self
        )
    }

    internal func setUpSelectionManager() -> TextSelectionManager {
        TextSelectionManager(
            layoutManager: layoutManager,
            textStorage: textStorage,
            layoutView: self, // TODO: This is an odd syntax... consider reworking this
            delegate: self
        )
    }
}
