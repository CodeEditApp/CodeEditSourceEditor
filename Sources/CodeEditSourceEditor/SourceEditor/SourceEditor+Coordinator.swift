//
//  SourceEditor+Coordinator.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 5/20/24.
//

import AppKit
import SwiftUI
import Combine
import CodeEditTextView

extension SourceEditor {
    @MainActor
    public class Coordinator: NSObject {
        private weak var controller: TextViewController?
        var isUpdatingFromRepresentable: Bool = false
        var isUpdateFromTextView: Bool = false
        var text: TextAPI
        @Binding var editorState: SourceEditorState

        private(set) var highlightProviders: [any HighlightProviding]

        private var cancellables: Set<AnyCancellable> = []

        init(text: TextAPI, editorState: Binding<SourceEditorState>, highlightProviders: [any HighlightProviding]?) {
            self.text = text
            self._editorState = editorState
            self.highlightProviders = highlightProviders ?? [TreeSitterClient()]
            super.init()
        }

        func setController(_ controller: TextViewController) {
            self.controller = controller
            // swiftlint:disable:this notification_center_detachment
            NotificationCenter.default.removeObserver(self)

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(textViewDidChangeText(_:)),
                name: TextView.textDidChangeNotification,
                object: controller.textView
            )

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(textControllerCursorsDidUpdate(_:)),
                name: TextViewController.cursorPositionUpdatedNotification,
                object: controller
            )

            // Needs to be put on the main runloop or SwiftUI gets mad
            NotificationCenter.default
                .publisher(
                    for: TextViewController.scrollPositionDidUpdateNotification,
                    object: controller
                )
                .receive(on: RunLoop.main)
                .sink { [weak self] notification in
                    self?.textControllerScrollDidChange(notification)
                }
                .store(in: &cancellables)
        }

        func updateHighlightProviders(_ highlightProviders: [any HighlightProviding]?) {
            guard let highlightProviders else {
                return // Keep our default `TreeSitterClient` if they're `nil`
            }
            // Otherwise, we can replace the stored providers.
            self.highlightProviders = highlightProviders
        }

        @objc func textViewDidChangeText(_ notification: Notification) {
            guard let textView = notification.object as? TextView else {
                return
            }
            // A plain string binding is one-way (from this view, up the hierarchy) so it's not in the state binding
            if case .binding(let binding) = text {
                binding.wrappedValue = textView.string
            }
        }

        @objc func textControllerCursorsDidUpdate(_ notification: Notification) {
            guard let controller = notification.object as? TextViewController else {
                return
            }
            updateState { $0.cursorPositions = controller.cursorPositions }
        }

        func textControllerScrollDidChange(_ notification: Notification) {
            guard let controller = notification.object as? TextViewController else {
                return
            }
            updateState { $0.scrollPosition = controller.scrollView.contentView.bounds.origin }
        }

        private func updateState(_ modifyCallback: (inout SourceEditorState) -> Void) {
            guard !isUpdatingFromRepresentable else { return }
            self.isUpdateFromTextView = true
            modifyCallback(&editorState)
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
}
