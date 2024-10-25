//
//  StyledRangeContainer.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 10/13/24.
//

import Foundation

class StyledRangeContainer {
    private var storage: [UUID: StyledRangeStore] = [:]
}

extension StyledRangeContainer: HighlightProviderStateDelegate {
    func applyHighlightResult(provider: UUID, highlights: [HighlightRange], rangeToHighlight: NSRange) {
        guard let storage = storage[provider] else {
            assertionFailure("No storage found for the given provider: \(provider)")
            return
        }
        
    }
}
