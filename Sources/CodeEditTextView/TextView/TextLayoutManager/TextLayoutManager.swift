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
    private var lineStorage: TextLineStorage

    init(textStorage: NSTextStorage) {
        self.textStorage = textStorage
        self.lineStorage = TextLineStorage()
        
    }

    private func prepareTextLines() {
        guard lineStorage.count == 0 else { return }
        var info = mach_timebase_info()
        guard mach_timebase_info(&info) == KERN_SUCCESS else { return }
        let start = mach_absolute_time()

        func getNextLine(in text: NSString, startingAt location: Int) -> NSRange? {
            let range = NSRange(location: location, length: 0)
            var end: Int = NSNotFound
            var contentsEnd: Int = NSNotFound
            text.getLineStart(nil, end: &end, contentsEnd: &contentsEnd, for: range)
            if end != NSNotFound && contentsEnd != NSNotFound && end != contentsEnd {
                return NSRange(location: contentsEnd, length: end - contentsEnd)
            } else {
                return nil
            }
        }
        var index = 0
        var newlineIndexes: [Int] = []
        while let range = getNextLine(in: textStorage.mutableString, startingAt: index) {
            index = NSMaxRange(range)
            newlineIndexes.append(index)
        }

        for idx in 0..<newlineIndexes.count {
            
        }

        /*
         let line = TextLine(stringRef: textStorage.mutableString, range: range)
         lineStorage.insert(line: line, atIndex: index, length: NSMaxRange(range) - index)
         */

        let end = mach_absolute_time()
        let elapsed = end - start
        let nanos = elapsed * UInt64(info.numer) / UInt64(info.denom)
        print("Layout Manager built in: ", TimeInterval(nanos) / TimeInterval(NSEC_PER_MSEC), "ms")
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
