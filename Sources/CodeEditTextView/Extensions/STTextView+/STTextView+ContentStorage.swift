//
//  File.swift
//  
//
//  Created by Khan Winter on 4/24/23.
//

import Foundation
import AppKit
import STTextView

extension STTextView {
    /// Convenience that unwraps `textContentManager` as an `NSTextContentStorage` subclass.
    var textContentStorage: NSTextContentStorage? {
        return textContentManager as? NSTextContentStorage
    }
}
