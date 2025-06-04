//
//  NSRect+Transform.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 6/4/25.
//

import AppKit

extension NSRect {
    func transform(x: CGFloat = 0, y: CGFloat = 0, width: CGFloat = 0, height: CGFloat = 0) -> NSRect {
        NSRect(
            x: self.origin.x + x,
            y: self.origin.y + y,
            width: self.width + width,
            height: self.height + height
        )
    }
}
