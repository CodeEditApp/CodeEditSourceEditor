//
//  StyledRangeContainer.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 10/13/24.
//

import Foundation

class StyledRangeContainer {
    typealias Run = StyledRangeStore.Run
    var _storage: [UUID: StyledRangeStore] = [:]

    init(documentLength: Int, providers: [UUID]) {
        for provider in providers {
            _storage[provider] = StyledRangeStore(documentLength: documentLength)
        }
    }

    func runsIn(range: NSRange) -> [Run] {
        
    }

    func storageUpdated(replacedContentIn range: Range<Int>, withCount newLength: Int) {
        _storage.values.forEach {
            $0.storageUpdated(replacedCharactersIn: range, withCount: newLength)
        }
    }
}

extension StyledRangeContainer: HighlightProviderStateDelegate {
    func applyHighlightResult(provider: UUID, highlights: [HighlightRange], rangeToHighlight: NSRange) {
        assert(rangeToHighlight != .notFound, "NSNotFound is an invalid highlight range")
        guard let storage = _storage[provider] else {
            assertionFailure("No storage found for the given provider: \(provider)")
            return
        }
        var runs: [Run] = []
        var lastIndex = rangeToHighlight.lowerBound

        for highlight in highlights {
            if highlight.range.lowerBound != lastIndex {
                runs.append(.empty(length: highlight.range.lowerBound - lastIndex))
            }
            // TODO: Modifiers
            runs.append(Run(length: highlight.range.length, capture: highlight.capture, modifiers: []))
            lastIndex = highlight.range.max
        }

        if lastIndex != rangeToHighlight.upperBound {
            runs.append(.empty(length: rangeToHighlight.upperBound - lastIndex))
        }

        storage.set(runs: runs, for: rangeToHighlight.intRange)
    }
}
