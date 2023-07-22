//
//  CursorLayer.swift
//  
//
//  Created by Khan Winter on 7/17/23.
//

import AppKit

class CursorLayer: CALayer {
    let rect: NSRect

    init(rect: NSRect) {
        self.rect = rect
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
