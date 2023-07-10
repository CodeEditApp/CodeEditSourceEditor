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

    func processMutation(
        _ mutation: TextMutation,
        in interface: TextInterface,
        with providers: WhitespaceProviders
    ) -> FilterAction {
        guard mutation.string == ""
                && mutation.range.length == 1
                && indentOption != .tab else {
            return .none
        }

        let lineRange = interface.lineRange(containing: mutation.range.location)
        guard let leadingWhitespace = interface.leadingRange(in: lineRange, within: .whitespacesWithoutNewlines),
              leadingWhitespace.contains(mutation.range.location) else {
            return .none
        }

        // Move to left of the whitespace and delete to the left-most tab column
        let indentLength = indentOption.stringValue.count
        var numberOfExtraSpaces = leadingWhitespace.length % indentLength
        if numberOfExtraSpaces == 0 {
            numberOfExtraSpaces = 4
        }

        interface.applyMutation(
            TextMutation(
                delete: NSRange(location: leadingWhitespace.max - numberOfExtraSpaces, length: numberOfExtraSpaces),
                limit: mutation.limit
            )
        )

        return .discard
    }
}
