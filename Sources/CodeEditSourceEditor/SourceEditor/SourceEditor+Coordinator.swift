//
//  SourceEditor+Coordinator.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 5/20/24.
//

import Foundation
import SwiftUI
import CodeEditTextView

extension SourceEditor {
    @MainActor
    public class Coordinator: NSObject {
        weak var controller: TextViewController?
        var isUpdatingFromRepresentable: Bool = false
        var isUpdateFromTextView: Bool = false
        var text: TextAPI
        @Binding var cursorPositions: [CursorPosition]

        private(set) var highlightProviders: [any HighlightProviding]

        init(text: TextAPI, cursorPositions: Binding<[CursorPosition]>, highlightProviders: [any HighlightProviding]?) {
            self.text = text
            self._cursorPositions = cursorPositions
            self.highlightProviders = highlightProviders ?? [TreeSitterClient()]
            super.init()

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(textViewDidChangeText(_:)),
                name: TextView.textDidChangeNotification,
                object: nil
            )

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(textControllerCursorsDidUpdate(_:)),
                name: TextViewController.cursorPositionUpdatedNotification,
                object: nil
            )
        }

        func updateHighlightProviders(_ highlightProviders: [any HighlightProviding]?) {
            guard let highlightProviders else {
                return // Keep our default `TreeSitterClient` if they're `nil`
            }
            // Otherwise, we can replace the stored providers.
            self.highlightProviders = highlightProviders
        }

        @objc func textViewDidChangeText(_ notification: Notification) {
            guard let textView = notification.object as? TextView,
                  let controller,
                  controller.textView === textView else {
                return
            }
            if case .binding(let binding) = text {
                binding.wrappedValue = textView.string
            }
        }

        @objc func textControllerCursorsDidUpdate(_ notification: Notification) {
            guard let notificationController = notification.object as? TextViewController,
                  notificationController === controller else {
                return
            }
            guard !isUpdatingFromRepresentable else { return }
            self.isUpdateFromTextView = true
            cursorPositions = notificationController.cursorPositions
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
}
