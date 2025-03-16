//
//  VisibleRangeProvider.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 10/13/24.
//

import AppKit
import CodeEditTextView

@MainActor
protocol VisibleRangeProviderDelegate: AnyObject {
    func visibleSetDidUpdate(_ newIndices: IndexSet)
}

/// Provides information to ``HighlightProviderState``s about what text is visible in the editor. Keeps it's contents
/// in sync with a text view and notifies listeners about changes so highlights can be applied to newly visible indices.
@MainActor
class VisibleRangeProvider {
    private weak var textView: TextView?
    weak var delegate: VisibleRangeProviderDelegate?

    var documentRange: NSRange {
        textView?.documentRange ?? .notFound
    }

    /// The set of visible indexes in the text view
    lazy var visibleSet: IndexSet = {
        return IndexSet(integersIn: textView?.visibleTextRange ?? NSRange())
    }()

    init(textView: TextView) {
        self.textView = textView

        if let scrollView = textView.enclosingScrollView {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(visibleTextChanged(_:)),
                name: NSView.frameDidChangeNotification,
                object: scrollView
            )

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(visibleTextChanged(_:)),
                name: NSView.boundsDidChangeNotification,
                object: scrollView.contentView
            )
        } else {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(visibleTextChanged(_:)),
                name: NSView.frameDidChangeNotification,
                object: textView
            )
        }
    }

    func updateVisibleSet(textView: TextView) {
        if let newVisibleRange = textView.visibleTextRange {
            visibleSet = IndexSet(integersIn: newVisibleRange)
        }
    }

    /// Updates the view to highlight newly visible text when the textview is scrolled or bounds change.
    @objc func visibleTextChanged(_ notification: Notification) {
        let textView: TextView
        if let clipView = notification.object as? NSClipView,
           let documentView = clipView.enclosingScrollView?.documentView as? TextView {
            textView = documentView
        } else if let scrollView = notification.object as? NSScrollView,
                  let documentView = scrollView.documentView as? TextView {
            textView = documentView
        } else if let documentView = notification.object as? TextView {
            textView = documentView
        } else {
            return
        }

        updateVisibleSet(textView: textView)

        delegate?.visibleSetDidUpdate(visibleSet)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
