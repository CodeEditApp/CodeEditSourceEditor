//
//  File.swift
//  
//
//  Created by Khan Winter on 7/16/23.
//

import Foundation

extension TextLineStorage {
    func linesStartingAt(_ minY: CGFloat, until maxY: CGFloat) -> TextLineStorageYIterator {
        return TextLineStorageYIterator(storage: self, minY: minY, maxY: maxY)
    }

    struct TextLineStorageYIterator: Sequence, IteratorProtocol {
        let storage: TextLineStorage
        let minY: CGFloat
        let maxY: CGFloat
        var currentPosition: TextLinePosition?

        mutating func next() -> TextLinePosition? {
            if let currentPosition {
                guard currentPosition.height + currentPosition.node.height < maxY,
                      let nextNode = currentPosition.node.getSuccessor() else { return nil }
                self.currentPosition = TextLinePosition(
                    node: nextNode,
                    offset: currentPosition.offset + currentPosition.node.length,
                    height: currentPosition.height + currentPosition.node.height
                )
                return self.currentPosition!
            } else if let nextPosition = storage.getLine(atPosition: minY) {
                self.currentPosition = nextPosition
                return nextPosition
            } else {
                return nil
            }
        }
    }

}
