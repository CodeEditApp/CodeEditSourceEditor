//
//  TabReplacementFilter.swift
//  
//
//  Created by Khan Winter on 1/28/23.
//

import Foundation
import TextFormation
import TextStory

struct TabReplacementFilter: Filter {
    let indentationUnit: String

    func processMutation(_ mutation: TextMutation, in interface: TextInterface) -> FilterAction {
        if mutation.string == "\t" {
            interface.applyMutation(TextMutation(insert: indentationUnit,
                                                 at: mutation.range.location,
                                                 limit: mutation.limit))
            return .discard
        } else {
            return .none
        }
    }
}
