//
//  FindViewController+Toggle.swift
//  CodeEditSourceEditor
//
//  Created by Austin Condiff on 4/3/25.
//

import AppKit

extension FindViewController {
    /// Show the find panel
    func showFindPanel(animated: Bool = true) {
        if isShowingFindPanel {
            // If panel is already showing, just focus the text field
            _ = findPanel?.becomeFirstResponder()
            return
        }

        isShowingFindPanel = true

        let updates: () -> Void = { [self] in
            // SwiftUI breaks things here, and refuses to return the correct `findPanel.fittingSize` so we
            // are forced to use a constant number.
            target?.findPanelWillShow(panelHeight: FindPanel.height)
            setFindPanelConstraintShow()
        }

        if animated {
            withAnimation(updates)
        } else {
            updates()
        }

        _ = findPanel?.becomeFirstResponder()
        findPanel?.addEventMonitor()
    }

    /// Hide the find panel
    func hideFindPanel(animated: Bool = true) {
        isShowingFindPanel = false
        _ = findPanel?.resignFirstResponder()
        findPanel?.removeEventMonitor()

        let updates: () -> Void = { [self] in
            target?.findPanelWillHide(panelHeight: FindPanel.height)
            setFindPanelConstraintHide()
        }

        if animated {
            withAnimation(updates)
        } else {
            updates()
        }

        // Set first responder back to text view
        if let textViewController = target as? TextViewController {
            _ = textViewController.textView.window?.makeFirstResponder(textViewController.textView)
        }
    }

    /// Runs the `animatable` callback in an animation context with implicit animation enabled.
    /// - Parameter animatable: The callback run in the animation context. Perform layout or view updates in this
    ///                         callback to have them animated.
    private func withAnimation(_ animatable: () -> Void) {
        NSAnimationContext.runAnimationGroup { animator in
            animator.duration = 0.2
            animator.allowsImplicitAnimation = true

            animatable()

            view.updateConstraints()
            view.layoutSubtreeIfNeeded()
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
