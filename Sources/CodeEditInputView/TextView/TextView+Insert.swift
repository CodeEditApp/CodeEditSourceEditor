//
//  TextView+Insert.swift
//  
//
//  Created by Khan Winter on 9/3/23.
//

import AppKit

extension TextView {
    public override func insertNewline(_ sender: Any?) {
        insertText(layoutManager.detectedLineEnding.rawValue)
    }
}
