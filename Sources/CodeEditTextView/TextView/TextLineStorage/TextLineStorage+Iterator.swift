//
//  File.swift
//  
//
//  Created by Khan Winter on 7/16/23.
//

import Foundation

extension TextLineStorage {
    func linesStartingAt(_ minY: CGFloat, until maxY: CGFloat) -> TextLineStorageYIterator {
        TextLineStorageYIterator(storage: self, minY: minY, maxY: maxY)
    }

    func linesInRange(_ range: NSRange) -> TextLineStorageRangeIterator {
        TextLineStorageRangeIterator(storage: self, range: range)
    }

    struct TextLineStorageYIterator: LazySequenceProtocol, IteratorProtocol {
        private let storage: TextLineStorage
        private let minY: CGFloat
        private let maxY: CGFloat
        private var currentPosition: TextLinePosition?

        init(storage: TextLineStorage, minY: CGFloat, maxY: CGFloat, currentPosition: TextLinePosition? = nil) {
            self.storage = storage
            self.minY = minY
            self.maxY = maxY
            self.currentPosition = currentPosition
        }

        mutating func next() -> TextLinePosition? {
            if let currentPosition {
                guard currentPosition.yPos < maxY,
                      let nextPosition = storage.getLine(
                        atIndex: currentPosition.range.max
                      ) else { return nil }
                self.currentPosition = nextPosition
                return self.currentPosition!
            } else if let nextPosition = storage.getLine(atPosition: minY) {
                self.currentPosition = nextPosition
                return nextPosition
            } else {
                return nil
            }
        }
    }

    struct TextLineStorageRangeIterator: LazySequenceProtocol, IteratorProtocol {
        private let storage: TextLineStorage
        private let range: NSRange
        private var currentPosition: TextLinePosition?

        init(storage: TextLineStorage, range: NSRange, currentPosition: TextLinePosition? = nil) {
            self.storage = storage
            self.range = range
            self.currentPosition = currentPosition
        }

        mutating func next() -> TextLinePosition? {
            if let currentPosition {
                guard currentPosition.range.max < range.max,
                      let nextPosition = storage.getLine(
                        atIndex: currentPosition.range.max
                      ) else { return nil }
                self.currentPosition = nextPosition
                return self.currentPosition!
            } else if let nextPosition = storage.getLine(atIndex: range.location) {
                self.currentPosition = nextPosition
                return nextPosition
            } else {
                return nil
            }
        }
    }
}

extension TextLineStorage: LazySequenceProtocol {
    func makeIterator() -> TextLineStorageIterator {
        TextLineStorageIterator(storage: self, currentPosition: nil)
    }

    struct TextLineStorageIterator: IteratorProtocol {
        private let storage: TextLineStorage
        private var currentPosition: TextLinePosition?

        init(storage: TextLineStorage, currentPosition: TextLinePosition? = nil) {
            self.storage = storage
            self.currentPosition = currentPosition
        }

        mutating func next() -> TextLinePosition? {
            if let currentPosition {
                guard currentPosition.range.max < storage.length,
                      let nextPosition = storage.getLine(
                        atIndex: currentPosition.range.max
                      ) else { return nil }
                self.currentPosition = nextPosition
                return self.currentPosition!
            } else if let nextPosition = storage.getLine(atIndex: 0) {
                self.currentPosition = nextPosition
                return nextPosition
            } else {
                return nil
            }
        }
    }
}
