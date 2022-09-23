//
//  NSRange+InputEdit.swift
//  
//
//  Created by Khan Winter on 9/12/22.
//

import Foundation
import SwiftTreeSitter

extension InputEdit {
    init?(range: NSRange, delta: Int, oldEndPoint: Point) {
        let startLocation = range.location
        let newEndLocation = NSMaxRange(range) + delta

        if newEndLocation < 0 {
            assertionFailure("Invalid range/delta")
            return nil
        }

        // TODO: - Ask why Neon only uses .zero for these
        let startPoint: Point = .zero
        let newEndPoint: Point = .zero

        self.init(startByte: UInt32(range.location * 2),
                  oldEndByte: UInt32(NSMaxRange(range) * 2),
                  newEndByte: UInt32(newEndLocation * 2),
                  startPoint: startPoint,
                  oldEndPoint: oldEndPoint,
                  newEndPoint: newEndPoint)
    }
}
