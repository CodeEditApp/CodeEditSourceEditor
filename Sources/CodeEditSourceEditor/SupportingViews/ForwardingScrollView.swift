//
//  ForwardingScrollView.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 4/15/25.
//

import Cocoa

class ForwardingScrollView: NSScrollView {

    weak var receiver: NSScrollView?

    override func scrollWheel(with event: NSEvent) {
        receiver?.scrollWheel(with: event)
    }

}
