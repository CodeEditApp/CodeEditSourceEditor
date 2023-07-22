//
//  LineFragmentLayer.swift
//  
//
//  Created by Khan Winter on 7/20/23.
//

import AppKit

class LineFragmentLayer: CALayer {
    private var lineFragment: LineFragment

    init(lineFragment: LineFragment) {
        self.lineFragment = lineFragment
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func prepareForReuse(lineFragment: LineFragment) {
        self.lineFragment = lineFragment
        self.frame.size = CGSize(width: lineFragment.width, height: lineFragment.height)
    }

    override func draw(in ctx: CGContext) {
        ctx.saveGState()
        ctx.textMatrix = .init(scaleX: 1, y: -1)
        ctx.translateBy(x: 0, y: lineFragment.height + (lineFragment.scaledHeight / 2))
        ctx.textPosition = CGPoint(x: 0, y: (lineFragment.scaledHeight - lineFragment.height) / 2)
        CTLineDraw(lineFragment.ctLine, ctx)
        ctx.restoreGState()
    }
}
