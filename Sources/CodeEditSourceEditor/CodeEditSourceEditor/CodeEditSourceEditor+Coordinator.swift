//
//  CodeEditSourceEditor+Coordinator.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 5/20/24.
//

import Foundation
import SwiftUI
import CodeEditTextView

extension CodeEditSourceEditor {
    @MainActor
    public class Coordinator: NSObject {
        weak var controller: TextViewController?
        var isUpdatingFromRepresentable: Bool = false
        var isUpdateFromTextView: Bool = false
        var text: TextAPI
        @Binding var cursorPositions: [CursorPosition]

        init(text: TextAPI, cursorPositions: Binding<[CursorPosition]>) {
            self.text = text
            self._cursorPositions = cursorPositions
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
