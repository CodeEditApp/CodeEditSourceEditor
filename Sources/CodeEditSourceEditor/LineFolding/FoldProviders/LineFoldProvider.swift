//
//  LineFoldProvider.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 5/7/25.
//

import AppKit
import CodeEditTextView

enum LineFoldProviderLineInfo {
    case startFold(rangeStart: Int, newDepth: Int)
    case endFold(rangeEnd: Int, newDepth: Int)

    var depth: Int {
        switch self {
        case .startFold(_, let newDepth):
            return newDepth
        case .endFold(_, let newDepth):
            return newDepth
        }
    }

    var rangeIndice: Int {
        switch self {
        case .startFold(let rangeStart, _):
            return rangeStart
        case .endFold(let rangeEnd, _):
            return rangeEnd
        }
    }
}

protocol LineFoldProvider: AnyObject {
    func foldLevelAtLine(
        lineNumber: Int,
        lineRange: NSRange,
        currentDepth: Int,
        text: NSTextStorage
    ) -> LineFoldProviderLineInfo?
}
