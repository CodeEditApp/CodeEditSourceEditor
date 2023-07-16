//
//  CETiledLayer.swift
//  
//
//  Created by Khan Winter on 6/27/23.
//

import Cocoa

class CETiledLayer: CATiledLayer {
    open override class func fadeDuration() -> CFTimeInterval {
        0
    }

    override public class func defaultAction(forKey event: String) -> CAAction? {
        return NSNull()
    }

    /// A dictionary containing layer actions.
    /// Disable animations
    override public var actions: [String: CAAction]? {
        get {
            super.actions
        }
        set {
            return
        }
    }

    public override init() {
        super.init()
        needsDisplayOnBoundsChange = true
    }

    public init(frame frameRect: CGRect) {
        super.init()
        needsDisplayOnBoundsChange = true
        frame = frameRect
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        needsDisplayOnBoundsChange = true
    }

    public override init(layer: Any) {
        super.init(layer: layer)
        needsDisplayOnBoundsChange = true
    }
}
