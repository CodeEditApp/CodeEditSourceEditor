//
//  LineFoldProvider.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 5/7/25.
//

import AppKit
import CodeEditTextView

protocol LineFoldProvider: AnyObject {
    func foldLevelAtLine(_ lineNumber: Int, substring: NSString) -> Int?
}
