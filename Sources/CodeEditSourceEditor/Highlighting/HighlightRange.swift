//
//  HighlightRange.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 9/14/22.
//

import Foundation

/// This class represents a range to highlight, as well as the capture name for syntax coloring.
public class HighlightRange {
    init(range: NSRange, capture: CaptureName?) {
        self.range = range
        self.capture = capture
    }

    let range: NSRange
    let capture: CaptureName?
}
