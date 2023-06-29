//
//  TextLine.swift
//  
//
//  Created by Khan Winter on 6/21/23.
//

import Foundation
import AppKit

/// Represents a displayable line of text.
/// Can be more than one line visually if lines are wrapped.
final class TextLine {
    typealias Attributes = [NSAttributedString.Key: Any]

    let id: UUID = UUID()
    var height: CGFloat = 0

    var ctLines: [CTLine]?

    private let typesetter: Typesetter

    init(typesetter: Typesetter) {
        self.typesetter = typesetter
        self.height = 0
    }

    init() {
        typesetter = .init(lineBreakMode: .byCharWrapping)
    }

    func prepareForDisplay(with attributes: [NSRange: Attributes]) {

    }
}

extension TextLine: Equatable {
    static func == (lhs: TextLine, rhs: TextLine) -> Bool {
        lhs.id == rhs.id
    }
}
