//
//  NSRange+TSRange.swift
//  
//
//  Created by Khan Winter on 2/26/23.
//

import Foundation
import SwiftTreeSitter

extension NSRange {
    var tsRange: TSRange {
        return TSRange(points: .zero..<(.zero), bytes: (UInt32(self.lowerBound) * 2)..<(UInt32(self.upperBound) * 2))
    }
}
