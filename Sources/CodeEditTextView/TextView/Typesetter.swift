//
//  Typesetter.swift
//  
//
//  Created by Khan Winter on 6/21/23.
//

import Foundation
import CoreText

final class Typesetter {
    var typesetter: CTTypesetter?
    var string: NSAttributedString?
    var lineBreakMode: TextView.LineBreakMode

    // MARK: - Init & Prepare

    init(lineBreakMode: TextView.LineBreakMode) {
        self.lineBreakMode = lineBreakMode
    }

    func prepareToTypeset(_ string: NSAttributedString) {
        self.string = string
        typesetter = CTTypesetterCreateWithAttributedString(string)
    }

    // MARK: - Generate lines

    func generateLines() -> [CTLine] {
        guard let typesetter, let string else {
            fatalError()
        }

        var startIndex = 0
        while startIndex < string.length {

        }

        return []
    }

    // MARK: - Line Breaks

    private func suggestLineBreak(
        using typesetter: CTTypesetter,
        string: NSAttributedString,
        startingOffset: Int,
        constrainingWidth: CGFloat
    ) -> Int {
        var breakIndex: Int
        switch lineBreakMode {
        case .byCharWrapping:
            breakIndex = CTTypesetterSuggestLineBreak(typesetter, startingOffset, constrainingWidth)
        case .byWordWrapping:
            breakIndex = CTTypesetterSuggestClusterBreak(typesetter, startingOffset, constrainingWidth)
        }

        return 0
    }
}
