//
//  String+NSRange.swift
//  
//
//  Created by Lukas Pistrol on 25.05.22.
//

import Foundation

extension String {
    // make string subscriptable with NSRange
    subscript(value: NSRange) -> Substring {
        let upperBound = String.Index(utf16Offset: Int(value.upperBound), in: self)
        let lowerBound = String.Index(utf16Offset: Int(value.lowerBound), in: self)
        print("Subscript:", value, lowerBound, upperBound)
        return self[lowerBound..<upperBound]
    }
}
