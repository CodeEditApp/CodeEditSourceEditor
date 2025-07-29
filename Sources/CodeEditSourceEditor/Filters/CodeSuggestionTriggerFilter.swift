//
//  CodeSuggestionTriggerFilter.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 7/22/25.
//

import Foundation
import TextFormation
import TextStory

struct CodeSuggestionTriggerFilter: Filter {
    let triggerCharacters: Set<String>
    let didTrigger: () -> Void

    func processMutation(
        _ mutation: TextMutation,
        in interface: TextInterface,
        with providers: WhitespaceProviders
    ) -> FilterAction {
        guard mutation.delta >= 0,
              let lastChar = mutation.string.last else {
            return .none
        }

        if triggerCharacters.contains(String(lastChar)) || lastChar.isNumber || lastChar.isLetter {
            didTrigger()
        }

        return .none
    }
}
