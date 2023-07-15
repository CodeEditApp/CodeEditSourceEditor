//
//  LineFragment.swift
//  
//
//  Created by Khan Winter on 6/29/23.
//

import AppKit

final class LineFragment {
    var ctLine: CTLine
    var width: CGFloat
    var height: CGFloat

    init(ctLine: CTLine, width: CGFloat, height: CGFloat) {
        self.ctLine = ctLine
        self.width = width
        self.height = height
    }
}
