//
//  File.swift
//  
//
//  Created by Lukas Pistrol on 25.05.22.
//

import Foundation
import SwiftTreeSitter

public class TreeSitterModel {
    public static let shared: TreeSitterModel = .init()

    private init() {}

    public lazy var swiftQuery: Query? = {
        return queryFor(.swift)
    }()

    public lazy var goQuery: Query? = {
        return queryFor(.go)
    }()

    public lazy var goModQuery: Query? = {
        return queryFor(.goMod)
    }()

    public lazy var htmlQuery: Query? = {
        return queryFor(.html)
    }()

    public lazy var jsonQuery: Query? = {
        return queryFor(.json)
    }()

    public lazy var rubyQuery: Query? = {
        return queryFor(.ruby)
    }()

    public lazy var yamlQuery: Query? = {
        return queryFor(.yaml)
    }()

    private func queryFor(_ codeLanguage: CodeLanguage) -> Query? {
        guard let language = codeLanguage.language,
              let url = codeLanguage.queryURL else { return nil }
        return try? language.query(contentsOf: url)
    }
}
