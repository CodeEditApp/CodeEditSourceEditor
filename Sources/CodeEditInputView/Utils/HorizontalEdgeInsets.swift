//
//  HorizontalEdgeInsets.swift
//  
//
//  Created by Khan Winter on 9/11/23.
//

import Foundation

public struct HorizontalEdgeInsets: Codable, Sendable, Equatable {
    public var left: CGFloat
    public var right: CGFloat

    public var horizontal: CGFloat {
        left + right
    }

    public init(left: CGFloat, right: CGFloat) {
        self.left = left
        self.right = right
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.left = try container.decode(CGFloat.self, forKey: .left)
        self.right = try container.decode(CGFloat.self, forKey: .right)
    }

    public static let zero: HorizontalEdgeInsets = {
        HorizontalEdgeInsets(left: 0, right: 0)
    }()
}
