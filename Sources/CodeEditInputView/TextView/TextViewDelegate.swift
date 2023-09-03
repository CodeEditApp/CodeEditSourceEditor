//
//  TextViewDelegate.swift
//  
//
//  Created by Khan Winter on 9/3/23.
//

import Foundation

public protocol TextViewDelegate: AnyObject {
    func textView(_ textView: TextView, willReplaceContents in: NSRange, with: String)
    func textView(_ textView: TextView, didReplaceContents in: NSRange, with: String)
    func textView(_ textView: TextView, shouldReplaceContents in: NSRange, with: String) -> Bool
}

public extension TextViewDelegate {
    func textView(_ textView: TextView, willReplaceContents in: NSRange, with: String) { }
    func textView(_ textView: TextView, didReplaceContents in: NSRange, with: String) { }
    func textView(_ textView: TextView, shouldReplaceContents in: NSRange, with: String) -> Bool { true }
}
