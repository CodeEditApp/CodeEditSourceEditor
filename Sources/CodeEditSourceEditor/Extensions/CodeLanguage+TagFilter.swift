//
//  CodeLanguage+TagFilter.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 5/25/24.
//

import CodeEditLanguages

extension CodeLanguage {
    fileprivate static let relevantLanguages = [
        CodeLanguage.html.tsName,
        CodeLanguage.javascript.tsName,
        CodeLanguage.typescript.tsName,
        CodeLanguage.jsx.tsName,
        CodeLanguage.tsx.tsName
    ]

    func shouldProcessTags() -> Bool {
        return Self.relevantLanguages.contains(self.tsName)
    }
}
