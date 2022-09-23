//
//  NSRange+NSTextRange.swift
//  
//
//  Created by Khan Winter on 9/13/22.
//

import AppKit

public extension NSTextRange {
    convenience init?(_ range: NSRange, provider: NSTextElementProvider) {
        let docLocation = provider.documentRange.location

        guard let start = provider.location?(docLocation, offsetBy: range.location) else {
            return nil
        }

        guard let end = provider.location?(start, offsetBy: range.length) else {
            return nil
        }

        self.init(location: start, end: end)
    }
}
