//
//  DeleteWhitespaceFilter.swift
//  
//
//  Created by Khan Winter on 1/28/23.
//

import Foundation
import TextFormation
import TextStory

/// Filter for quickly deleting indent whitespace
struct DeleteWhitespaceFilter: Filter {
    let indentOption: IndentOption

    func processMutation(_ mutation: TextMutation, in interface: TextInterface) -> FilterAction {
        guard mutation.string == "" && mutation.range.length == 1 && indentOption != .tab else {
            return .none
        }

        // Walk backwards from the mutation, grabbing as much whitespace as possible
        guard let preceedingNonWhitespace = interface.findPrecedingOccurrenceOfCharacter(
            in: CharacterSet.whitespaces.inverted,
            from: mutation.range.max
        ) else {
            return .none
        }

        let indentLength = indentOption.stringValue.count
        let length = mutation.range.max - preceedingNonWhitespace
        let numberOfExtraSpaces = length % indentLength

        if numberOfExtraSpaces == 0 && length >= indentLength {
            interface.applyMutation(
                TextMutation(delete: NSRange(location: mutation.range.max - indentLength,
                                             length: indentLength),
                             limit: mutation.limit)
            )
            return .discard
        }

        return .none
    }
}
