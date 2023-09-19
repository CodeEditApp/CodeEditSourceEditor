//
//  LineFragment.swift
//  
//
//  Created by Khan Winter on 6/29/23.
//

import AppKit

public final class LineFragment: Identifiable, Equatable {
    public let id = UUID()
    private(set) public var ctLine: CTLine
    public let width: CGFloat
    public let height: CGFloat
    public let descent: CGFloat
    public let scaledHeight: CGFloat

    public var heightDifference: CGFloat {
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

    public static func == (lhs: LineFragment, rhs: LineFragment) -> Bool {
        lhs.id == rhs.id
    }
}
