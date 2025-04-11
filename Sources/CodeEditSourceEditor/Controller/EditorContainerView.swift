//
//  EditorContainerView.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 4/10/25.
//

import AppKit

class EditorContainerView: NSView {
    weak var scrollView: NSScrollView?
    weak var minimapView: MinimapView?

    init(scrollView: NSScrollView, minimapView: MinimapView) {
        self.scrollView = scrollView
        self.minimapView = minimapView

        super.init(frame: .zero)

        self.translatesAutoresizingMaskIntoConstraints = false

        addSubview(scrollView)
        addSubview(minimapView)

        scrollView.hasVerticalScroller = true

        let maxWidthConstraint = minimapView.widthAnchor.constraint(lessThanOrEqualToConstant: 150)
        let relativeWidthConstraint = minimapView.widthAnchor.constraint(
            equalTo: widthAnchor,
            multiplier: 0.18
        )
        relativeWidthConstraint.priority = .defaultLow

        guard let scrollerAnchor = scrollView.verticalScroller?.leadingAnchor else {
            assertionFailure("Scroll view failed to create a scroller.")
            return
        }

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),

            minimapView.topAnchor.constraint(equalTo: topAnchor),
            minimapView.bottomAnchor.constraint(equalTo: bottomAnchor),
            minimapView.trailingAnchor.constraint(equalTo: scrollerAnchor),
            maxWidthConstraint,
            relativeWidthConstraint
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
