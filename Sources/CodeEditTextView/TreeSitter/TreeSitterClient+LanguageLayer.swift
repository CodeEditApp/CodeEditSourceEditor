//
//  TreeSitterClient+LanguageLayer.swift
//  
//
//  Created by Khan Winter on 3/8/23.
//

import Foundation
import CodeEditLanguages
import SwiftTreeSitter

extension TreeSitterClient {
    class LanguageLayer {
        init(id: TreeSitterLanguage,
             parser: Parser,
             tree: Tree? = nil,
             languageQuery: Query? = nil,
             ranges: [NSRange]) {
            self.id = id
            self.parser = parser
            self.tree = tree
            self.languageQuery = languageQuery
            self.ranges = ranges
        }

        var id: TreeSitterLanguage
        var parser: Parser
        var tree: Tree?
        var languageQuery: Query?
        var ranges: [NSRange]
    }
}
