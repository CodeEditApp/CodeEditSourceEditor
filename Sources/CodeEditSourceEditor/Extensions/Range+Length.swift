//
//  Range+Length.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 10/25/24.
//

import Foundation

extension Range where Bound == Int {
    var length: Bound { upperBound - lowerBound }

    init(lowerBound: Int, length: Int) {
        self = lowerBound..<(lowerBound + length)
    }
}
