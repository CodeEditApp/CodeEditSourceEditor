//
//  LineFragment.swift
//  
//
//  Created by Khan Winter on 6/29/23.
//

import AppKit

struct LineFragment {
    var ctLine: CTLine
    var width: CGFloat
    var height: CGFloat
    var scaledHeight: CGFloat

    init(ctLine: CTLine, width: CGFloat, height: CGFloat, lineHeightMultiplier: CGFloat) {
        self.ctLine = ctLine
        self.width = width
        self.height = height
        self.scaledHeight = height * lineHeightMultiplier
    }
}
