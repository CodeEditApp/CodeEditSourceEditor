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

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),

            minimapView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            minimapView.bottomAnchor.constraint(equalTo: bottomAnchor),
            minimapView.trailingAnchor.constraint(equalTo: trailingAnchor),
            minimapView.widthAnchor.constraint(equalToConstant: 150)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
