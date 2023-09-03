//
//  TextLayoutManager+Iterator.swift
//  
//
//  Created by Khan Winter on 8/21/23.
//

import Foundation

public extension TextLayoutManager {
    public func visibleLines() -> Iterator {
        let visibleRect = delegate?.visibleRect ?? NSRect(
            x: 0,
            y: 0,
            width: 0,
            height: estimatedHeight()
        )
        return Iterator(minY: max(visibleRect.minY, 0), maxY: max(visibleRect.maxY, 0), storage: self.lineStorage)
    }

    public struct Iterator: LazySequenceProtocol, IteratorProtocol {
        private var storageIterator: TextLineStorage<TextLine>.TextLineStorageYIterator

        init(minY: CGFloat, maxY: CGFloat, storage: TextLineStorage<TextLine>) {
            storageIterator = storage.linesStartingAt(minY, until: maxY)
        }

        public mutating func next() -> TextLineStorage<TextLine>.TextLinePosition? {
            storageIterator.next()
        }
    }
}
