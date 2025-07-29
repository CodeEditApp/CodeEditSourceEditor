//
//  CodeSuggestionPreviewView.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 7/28/25.
//

import SwiftUI

final class CodeSuggestionPreviewView: NSVisualEffectView {
    private let spacing: CGFloat = 5

    var sourcePreview: String? {
        didSet {
            sourcePreviewLabel.stringValue = sourcePreview ?? ""
            sourcePreviewLabel.isHidden = sourcePreview == nil
        }
    }

    var documentation: String? {
        didSet {
            documentationLabel.stringValue = documentation ?? ""
            documentationLabel.isHidden = documentation == nil
        }
    }

    var pathComponents: [String] = [] {
        didSet {
            configurePathComponentsLabel()
        }
    }

    var targetRange: CursorPosition? {
        didSet {
            configurePathComponentsLabel()
        }
    }

    var font: NSFont = .systemFont(ofSize: 12) {
        didSet {
            sourcePreviewLabel.font = font
            pathComponentsLabel.font = font
        }
    }
    var documentationFont: NSFont = .systemFont(ofSize: 12) {
        didSet {
            documentationLabel.font = documentationFont
        }
    }

    var stackView: NSStackView = NSStackView()
    var dividerView: NSView = NSView()
    var sourcePreviewLabel: NSTextField = NSTextField()
    var documentationLabel: NSTextField = NSTextField()
    var pathComponentsLabel: NSTextField = NSTextField()

    init() {
        super.init(frame: .zero)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = spacing
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)
        stackView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        addSubview(stackView)

        dividerView.translatesAutoresizingMaskIntoConstraints = false
        dividerView.wantsLayer = true
        dividerView.layer?.backgroundColor = NSColor.separatorColor.cgColor
        addSubview(dividerView)

        self.material = .windowBackground
        self.blendingMode = .behindWindow

        styleStaticLabel(sourcePreviewLabel)
        styleStaticLabel(documentationLabel)
        styleStaticLabel(pathComponentsLabel)

        stackView.addArrangedSubview(sourcePreviewLabel)
        stackView.addArrangedSubview(documentationLabel)
        stackView.addArrangedSubview(pathComponentsLabel)

        NSLayoutConstraint.activate([
            dividerView.topAnchor.constraint(equalTo: topAnchor),
            dividerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dividerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dividerView.heightAnchor.constraint(equalToConstant: 1),

            stackView.topAnchor.constraint(equalTo: dividerView.bottomAnchor, constant: spacing),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -SuggestionController.WINDOW_PADDING),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 13),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -13)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setPreferredMaxLayoutWidth(width: CGFloat) {
        sourcePreviewLabel.preferredMaxLayoutWidth = width
        documentationLabel.preferredMaxLayoutWidth = width
        pathComponentsLabel.preferredMaxLayoutWidth = width
    }

    private func styleStaticLabel(_ label: NSTextField) {
        label.isEditable = false
        label.allowsDefaultTighteningForTruncation = false
        label.isBezeled = false
        label.isBordered = false
        label.backgroundColor = .clear
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    private func configurePathComponentsLabel() {
        // TODO: This
        pathComponentsLabel.isHidden = true
    }
}
