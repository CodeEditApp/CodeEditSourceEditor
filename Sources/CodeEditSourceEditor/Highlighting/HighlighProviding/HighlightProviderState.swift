//
//  HighlightProviderState.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 10/13/24.
//

import Foundation
import CodeEditLanguages
import CodeEditTextView
import OSLog

protocol HighlightProviderStateDelegate: AnyObject {
    func applyHighlightResult(provider: UUID, highlights: [HighlightRange], rangeToHighlight: NSRange)
}

@MainActor
class HighlightProviderState {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "", category: "HighlightProviderState")

    /// The length to chunk ranges into when passing to the highlighter.
    private static let rangeChunkLimit = 4096

    // MARK: - State

    /// A unique identifier for this provider. Used by the delegate to determine the source of results.
    private let id: UUID = UUID()

    /// Any indexes that highlights have been requested for, but haven't been applied.
    /// Indexes/ranges are added to this when highlights are requested and removed
    /// after they are applied
    private var pendingSet: IndexSet = .init()

    /// The set of valid indexes
    private var validSet: IndexSet = .init()

    // MARK: - Providers

    private weak var delegate: HighlightProviderStateDelegate?

    /// Calculates invalidated ranges given an edit.
    private weak var highlightProvider: HighlightProviding?

    /// Provides a constantly updated visible index set.
    private weak var visibleRangeProvider: VisibleRangeProvider?

    /// A weak reference to the text view, used by the highlight provider.
    private weak var textView: TextView?

    private var visibleSet: IndexSet {
        visibleRangeProvider?.visibleSet ?? IndexSet()
    }

    private var documentSet: IndexSet {
        IndexSet(integersIn: visibleRangeProvider?.documentRange ?? .zero)
    }

    /// Creates a new highlight provider state object.
    /// Sends the `setUp` message to the highlight provider object.
    /// - Parameters:
    ///   - delegate: The delegate for this provider. Is passed information about ranges to highlight.
    ///   - highlightProvider: The object to query for highlight information.
    ///   - textView: The text view to highlight, used by the highlight provider.
    ///   - visibleRangeProvider: A visible range provider for determining which ranges to query.
    ///   - language: The language to set up the provider with.
    init(
        delegate: HighlightProviderStateDelegate,
        highlightProvider: HighlightProviding,
        textView: TextView,
        visibleRangeProvider: VisibleRangeProvider,
        language: CodeLanguage
    ) {
        self.delegate = delegate
        self.highlightProvider = highlightProvider
        self.textView = textView
        self.visibleRangeProvider = visibleRangeProvider

        highlightProvider.setUp(textView: textView, codeLanguage: language)
    }

    func setLanguage(language: CodeLanguage) {
        guard let textView else { return }
        highlightProvider?.setUp(textView: textView, codeLanguage: language)
        invalidate()
    }

    /// Invalidates all pending and valid ranges, resetting the provider.
    func invalidate() {
        validSet.removeAll()
        pendingSet.removeAll()
        highlightInvalidRanges()
    }
}

private extension HighlightProviderState {
    /// Invalidates a given range and adds it to the queue to be highlighted.
    /// - Parameter range: The range to invalidate.
    func invalidate(range: NSRange) {
        let set = IndexSet(integersIn: range)

        if set.isEmpty {
            return
        }

        validSet.subtract(set)

        highlightInvalidRanges()
    }

    /// Accumulates all pending ranges and calls `queryHighlights`.
    func highlightInvalidRanges() {
        var ranges: [NSRange] = []
        while let nextRange = getNextRange() {
            ranges.append(nextRange)
        }
        queryHighlights(for: ranges)
    }

    /// Gets the next `NSRange` to highlight based on the invalid set, visible set, and pending set.
    /// - Returns: An `NSRange` to highlight if it could be fetched.
    func getNextRange() -> NSRange? {
        let set: IndexSet = documentSet // All text
            .subtracting(validSet)      // Subtract valid = Invalid set
            .intersection(visibleSet)   // Only visible indexes
            .subtracting(pendingSet)    // Don't include pending indexes

        guard let range = set.rangeView.first else {
            return nil
        }

        // Chunk the ranges in sets of rangeChunkLimit characters.
        return NSRange(
            location: range.lowerBound,
            length: min(Self.rangeChunkLimit, range.upperBound - range.lowerBound)
        )
    }

    /// Queries for highlights for the given ranges
    /// - Parameter rangesToHighlight: The ranges to request highlights for.
    func queryHighlights(for rangesToHighlight: [NSRange]) {
        guard let textView else { return }
        for range in rangesToHighlight {
            highlightProvider?.queryHighlightsFor(textView: textView, range: range) { [weak self] result in
                guard let providerId = self?.id else { return }
                assert(Thread.isMainThread, "Highlighted ranges called on non-main thread.")
                switch result {
                case .success(let highlights):
                    self?.delegate?.applyHighlightResult(
                        provider: providerId,
                        highlights: highlights,
                        rangeToHighlight: range
                    )
                case .failure:
                    self?.invalidate(range: range)
                }
                self?.pendingSet.remove(integersIn: range)
            }
        }
    }
}
