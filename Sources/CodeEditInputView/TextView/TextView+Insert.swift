//
//  TextView+Insert.swift
//  
//
//  Created by Khan Winter on 9/3/23.
//

import AppKit

extension TextView {
    override public func insertNewline(_ sender: Any?) {
        insertText(layoutManager.detectedLineEnding.rawValue)
    }

    override public func insertTab(_ sender: Any?) {
        insertText("\t")
    }
}
