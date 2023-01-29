//
//  NewlineFilter.swift
//  
//
//  Created by Khan Winter on 1/28/23.
//

import Foundation
import TextFormation
import TextStory

/// A newline filter almost entirely similar to `TextFormation`s standard implementation.
struct NewlineFilter: Filter {
    func processMutation(_ mutation: TextStory.TextMutation,
                         in interface: TextFormation.TextInterface) -> TextFormation.FilterAction {
        recognizer.processMutation(mutation)

        switch recognizer.state {
        case .triggered:
            return filterHandler(mutation, in: interface)
        case .tracking, .idle:
            return .none
        }
    }

    private let recognizer: ConsecutiveCharacterRecognizer
    let providers: WhitespaceProviders

    init(whitespaceProviders: WhitespaceProviders) {
        self.recognizer = ConsecutiveCharacterRecognizer(matching: "\n")
        self.providers = whitespaceProviders
    }

    private func filterHandler(_ mutation: TextMutation, in interface: TextInterface) -> FilterAction {
        interface.applyMutation(mutation)

        let range = NSRange(location: mutation.postApplyRange.max, length: 0)

        let value = providers.leadingWhitespace(range, interface)

        interface.insertString(value, at: mutation.postApplyRange.max)

        return .discard
    }
}
