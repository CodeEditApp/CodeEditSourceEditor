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
    let descent: CGFloat
    let scaledHeight: CGFloat

    @inlinable
    var heightDifference: CGFloat {
        scaledHeight - height
    }

    init(
        ctLine: CTLine,
        width: CGFloat,
        height: CGFloat,
        descent: CGFloat,
        lineHeightMultiplier: CGFloat
    ) {
        self.ctLine = ctLine
        self.width = width
        self.height = height
        self.descent = descent
        self.scaledHeight = height * lineHeightMultiplier
    }
}
