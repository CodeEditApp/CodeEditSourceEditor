//
//  STTextViewController+CaptureNames.swift
//  CodeEditTextView
//
//  Created by Lukas Pistrol on 16.08.22.
//

import Foundation

internal extension STTextViewController {
    
    /// A collection of possible capture names for `tree-sitter` with their respected raw values.
    enum CaptureNames: String, CaseIterable {
        case include
        case constructor
        case keyword
        case boolean
        case `repeat`
        case conditional
        case tag
        case comment
        case variable
        case property
        case function
        case method
        case number
        case float
        case string
        case type
        case parameter
        case typeAlternate = "type_alternate"
        case variableBuiltin = "variable.builtin"
        case keywordReturn = "keyword.return"
        case keywordFunction = "keyword.function"

        /// Returns a specific capture name case from a given string.
        /// - Parameter string: A string to get the capture name from
        /// - Returns: A `CaptureNames` case
        static func fromString(_ string: String?) -> CaptureNames? {
            allCases.first { $0.rawValue == string }
        }
    }
}
