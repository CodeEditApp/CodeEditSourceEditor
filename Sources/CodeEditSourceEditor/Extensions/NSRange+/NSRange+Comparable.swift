//
//  NSRange+Comparable.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 3/15/23.
//

import Foundation

extension NSRange: Comparable {
    public static func == (lhs: NSRange, rhs: NSRange) -> Bool {
        return lhs.location == rhs.location && lhs.length == rhs.length
    }

    public static func < (lhs: NSRange, rhs: NSRange) -> Bool {
        return lhs.location < rhs.location
    }
}
