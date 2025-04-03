//
//  FindViewController.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 3/10/25.
//

import AppKit
import CodeEditTextView

/// Creates a container controller for displaying and hiding a find panel with a content view.
final class FindViewController: NSViewController {
    weak var target: FindPanelTarget?
    var childView: NSView
    var findPanel: FindPanel!
    var findMatches: [NSRange] = []
    var currentFindMatchIndex: Int = 0
    var findText: String = ""
    var findPanelVerticalConstraint: NSLayoutConstraint!
    var isShowingFindPanel: Bool = false

    init(target: FindPanelTarget, childView: NSView) {
        self.target = target
        self.childView = childView
        super.init(nibName: nil, bundle: nil)
        self.findPanel = FindPanel(delegate: self, textView: target as? NSView)

        // Add notification observer for text changes
        if let textViewController = target as? TextViewController {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(textDidChange),
                name: TextView.textDidChangeNotification,
                object: textViewController.textView
            )
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func textDidChange() {
        // Only update if we have find text
        if !findText.isEmpty {
            performFind(query: findText)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        super.loadView()

        // Set up the `childView` as a subview of our view. Constrained to all edges, except the top is constrained to
        // the find panel's bottom
        // The find panel is constrained to the top of the view.
        // The find panel's top anchor when hidden, is equal to it's negated height hiding it above the view's contents.
        // When visible, it's set to 0.

        view.clipsToBounds = false
        view.addSubview(findPanel)
        view.addSubview(childView)

        // Ensure find panel is always on top
        findPanel.wantsLayer = true
        findPanel.layer?.zPosition = 1000

        findPanelVerticalConstraint = findPanel.topAnchor.constraint(equalTo: view.topAnchor)

        NSLayoutConstraint.activate([
            // Constrain find panel
            findPanelVerticalConstraint,
            findPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            findPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // Constrain child view
            childView.topAnchor.constraint(equalTo: view.topAnchor),
            childView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            childView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            childView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        if isShowingFindPanel { // Update constraints for initial state
            setFindPanelConstraintShow()
        } else {
            setFindPanelConstraintHide()
        }
    }

    /// Sets the find panel constraint to show the find panel.
    /// Can be animated using implicit animation.
    private func setFindPanelConstraintShow() {
        // Update the find panel's top to be equal to the view's top.
        findPanelVerticalConstraint.constant = view.safeAreaInsets.top
        findPanelVerticalConstraint.isActive = true
    }

    /// Sets the find panel constraint to hide the find panel.
    /// Can be animated using implicit animation.
    private func setFindPanelConstraintHide() {
        // Update the find panel's top anchor to be equal to it's negative height, hiding it above the view.

        // SwiftUI hates us. It refuses to move views outside of the safe are if they don't have the `.ignoresSafeArea`
        // modifier, but with that modifier on it refuses to allow it to be animated outside the safe area.
        // The only way I found to fix it was to multiply the height by 3 here.
        findPanelVerticalConstraint.constant = view.safeAreaInsets.top - (FindPanel.height * 3)
        findPanelVerticalConstraint.isActive = true
    }
}
