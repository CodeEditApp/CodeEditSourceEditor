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

    struct TextLineStorageYIterator: Sequence, IteratorProtocol {
        let storage: TextLineStorage
        let minY: CGFloat
        let maxY: CGFloat
        var currentPosition: TextLinePosition?

        mutating func next() -> TextLinePosition? {
            if let currentPosition {
                guard currentPosition.height < maxY,
                      let nextPosition = storage.getLine(
                        atIndex: currentPosition.offset + currentPosition.node.length
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

    struct TextLineStorageRangeIterator: Sequence, IteratorProtocol {
        let storage: TextLineStorage
        let range: NSRange
        var currentPosition: TextLinePosition?

        mutating func next() -> TextLinePosition? {
            if let currentPosition {
                guard currentPosition.offset + currentPosition.node.length < NSMaxRange(range),
                      let nextPosition = storage.getLine(
                        atIndex: currentPosition.offset + currentPosition.node.length
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

extension TextLineStorage: Sequence {
    func makeIterator() -> TextLineStorageIterator {
        TextLineStorageIterator(storage: self, currentPosition: nil)
    }

    struct TextLineStorageIterator: IteratorProtocol {
        let storage: TextLineStorage
        var currentPosition: TextLinePosition?

        mutating func next() -> TextLinePosition? {
            if let currentPosition {
                guard currentPosition.offset + currentPosition.node.length < storage.length,
                      let nextPosition = storage.getLine(
                        atIndex: currentPosition.offset + currentPosition.node.length
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
