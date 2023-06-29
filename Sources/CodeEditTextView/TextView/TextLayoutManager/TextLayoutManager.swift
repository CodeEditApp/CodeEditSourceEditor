//
//  TextLayoutManager.swift
//  
//
//  Created by Khan Winter on 6/21/23.
//

import Foundation
import AppKit

protocol TextLayoutManagerDelegate: AnyObject { }

class TextLayoutManager: NSObject {
    private unowned var textStorage: NSTextStorage
    private var lineStorage: TextLayoutLineStorage

    init(textStorage: NSTextStorage) {
        self.textStorage = textStorage
        self.lineStorage = TextLayoutLineStorage()
    }

    func prepareForDisplay() {
        guard lineStorage.count == 0 else { return }
        var string = textStorage.string as String
        string.makeContiguousUTF8()
        var info = mach_timebase_info()
        guard mach_timebase_info(&info) == KERN_SUCCESS else { return }

        let start = mach_absolute_time()
        var index = 0
        for (currentIndex, char) in string.lazy.enumerated() {
            if char == "\n" {
                lineStorage.insert(atIndex: index, length: currentIndex - index)
                index = currentIndex
            }
        }
        let end = mach_absolute_time()

        let elapsed = end - start

        let nanos = elapsed * UInt64(info.numer) / UInt64(info.denom)
        print(TimeInterval(nanos) / TimeInterval(NSEC_PER_MSEC))
        print(lineStorage.count)
    }

    func estimatedHeight() -> CGFloat { 0 }
    func estimatedWidth() -> CGFloat { 0 }
}

extension TextLayoutManager: NSTextStorageDelegate {
    func textStorage(
        _ textStorage: NSTextStorage,
        didProcessEditing editedMask: NSTextStorageEditActions,
        range editedRange: NSRange,
        changeInLength delta: Int
    ) {
        
    }
}
