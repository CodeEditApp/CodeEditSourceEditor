//
//  File.swift
//  
//
//  Created by Khan Winter on 8/24/23.
//

import Foundation

extension TextLineStorage where Data: Identifiable {
    struct TextLinePosition {
        init(data: Data, range: NSRange, yPos: CGFloat, height: CGFloat, index: Int) {
            self.data = data
            self.range = range
            self.yPos = yPos
            self.height = height
            self.index = index
        }

        init(position: NodePosition) {
            self.data = position.node.data
            self.range = NSRange(location: position.textPos, length: position.node.length)
            self.yPos = position.yPos
            self.height = position.node.height
            self.index = position.index
        }

        /// The data stored at the position
        let data: Data
        /// The range represented by the data
        let range: NSRange
        /// The y position of the data, on a top down y axis
        let yPos: CGFloat
        /// The height of the stored data
        let height: CGFloat
        /// The index of the position.
        let index: Int
    }

    internal struct NodePosition {
        /// The node storing information and the data stored at the position.
        let node: Node<Data>
        /// The y position of the data, on a top down y axis
        let yPos: CGFloat
        /// The location of the node in the document
        let textPos: Int
        /// The index of the node in the document.
        let index: Int
    }

    struct BuildItem {
        let data: Data
        let length: Int
    }
}
