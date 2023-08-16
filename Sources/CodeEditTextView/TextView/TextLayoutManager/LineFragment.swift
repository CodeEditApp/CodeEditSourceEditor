//
//  LineFragment.swift
//  
//
//  Created by Khan Winter on 6/29/23.
//

import AppKit

final class LineFragment: Identifiable {
    let id = UUID()
    var ctLine: CTLine
    let width: CGFloat
    let height: CGFloat
    let scaledHeight: CGFloat

    init(
        ctLine: CTLine,
        width: CGFloat,
        height: CGFloat,
        lineHeightMultiplier: CGFloat
    ) {
        self.ctLine = ctLine
        self.width = width
        self.height = height
        self.scaledHeight = height * lineHeightMultiplier
    }
}
