//
//  SourceEditor.swift
//  CodeEditSourceEditor
//
//  Created by Lukas Pistrol on 24.05.22.
//

import AppKit
import SwiftUI
import CodeEditTextView
import CodeEditLanguages

/// A SwiftUI View that provides source editing functionality.
public struct SourceEditor: NSViewControllerRepresentable {
    package enum TextAPI {
        case binding(Binding<String>)
        case storage(NSTextStorage)
    }

    /// Initializes a new source editor
    /// - Parameters:
    ///   - text: The text content
    ///   - language: The language for syntax highlighting
    ///   - configuration: A configuration object, determining appearance, layout, behaviors  and more.
    ///                    See ``SourceEditorConfiguration``.
    ///   - cursorPositions: The cursor's position in the editor, measured in `(lineNum, columnNum)`
    ///   - highlightProviders: A set of classes you provide to perform syntax highlighting. Leave this as `nil` to use
    ///                         the default `TreeSitterClient` highlighter.
    ///   - undoManager: The undo manager for the text view. Defaults to `nil`, which will create a new CEUndoManager
    ///   - coordinators: Any text coordinators for the view to use. See ``TextViewCoordinator`` for more information.
    public init(
        _ text: Binding<String>,
        language: CodeLanguage,
        configuration: SourceEditorConfiguration,
        cursorPositions: Binding<[CursorPosition]>,
        highlightProviders: [any HighlightProviding]? = nil,
        undoManager: CEUndoManager? = nil,
        coordinators: [any TextViewCoordinator] = []
    ) {
        self.text = .binding(text)
        self.language = language
        self.configuration = configuration
        self.cursorPositions = cursorPositions
        self.highlightProviders = highlightProviders
        self.undoManager = undoManager
        self.coordinators = coordinators
    }

    /// Initializes a new source editor
    /// - Parameters:
    ///   - text: The text content
    ///   - language: The language for syntax highlighting
    ///   - configuration: A configuration object, determining appearance, layout, behaviors  and more.
    ///                    See ``SourceEditorConfiguration``.
    ///   - cursorPositions: The cursor's position in the editor, measured in `(lineNum, columnNum)`
    ///   - highlightProviders: A set of classes you provide to perform syntax highlighting. Leave this as `nil` to use
    ///                         the default `TreeSitterClient` highlighter.
    ///   - undoManager: The undo manager for the text view. Defaults to `nil`, which will create a new CEUndoManager
    ///   - coordinators: Any text coordinators for the view to use. See ``TextViewCoordinator`` for more information.
    public init(
        _ text: NSTextStorage,
        language: CodeLanguage,
        configuration: SourceEditorConfiguration,
        cursorPositions: Binding<[CursorPosition]>,
        highlightProviders: [any HighlightProviding]? = nil,
        undoManager: CEUndoManager? = nil,
        coordinators: [any TextViewCoordinator] = []
    ) {
        self.text = .storage(text)
        self.language = language
        self.configuration = configuration
        self.cursorPositions = cursorPositions
        self.highlightProviders = highlightProviders
        self.undoManager = undoManager
        self.coordinators = coordinators
    }

    package var text: TextAPI
    private var language: CodeLanguage
    private var configuration: SourceEditorConfiguration
    package var cursorPositions: Binding<[CursorPosition]>
    private var highlightProviders: [any HighlightProviding]?
    private var undoManager: CEUndoManager?
    package var coordinators: [any TextViewCoordinator]

    public typealias NSViewControllerType = TextViewController

    public func makeNSViewController(context: Context) -> TextViewController {
        let controller = TextViewController(
            string: "",
            language: language,
            configuration: configuration,
            cursorPositions: cursorPositions.wrappedValue,
            highlightProviders: context.coordinator.highlightProviders,
            undoManager: undoManager,
            coordinators: coordinators
        )
        switch text {
        case .binding(let binding):
            controller.textView.setText(binding.wrappedValue)
        case .storage(let textStorage):
            controller.textView.setTextStorage(textStorage)
        }
        if controller.textView == nil {
            controller.loadView()
        }
        if !cursorPositions.isEmpty {
            controller.setCursorPositions(cursorPositions.wrappedValue)
        }

        context.coordinator.controller = controller
        return controller
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(text: text, cursorPositions: cursorPositions, highlightProviders: highlightProviders)
    }

    public func updateNSViewController(_ controller: TextViewController, context: Context) {
        context.coordinator.updateHighlightProviders(highlightProviders)

        if !context.coordinator.isUpdateFromTextView {
            // Prevent infinite loop of update notifications
            context.coordinator.isUpdatingFromRepresentable = true
            controller.setCursorPositions(cursorPositions.wrappedValue)
            context.coordinator.isUpdatingFromRepresentable = false
        } else {
            context.coordinator.isUpdateFromTextView = false
        }

        // Do manual diffing to reduce the amount of reloads.
        // This helps a lot in view performance, as it otherwise gets triggered on each environment change.
        guard !paramsAreEqual(controller: controller, coordinator: context.coordinator) else {
            return
        }

        if controller.language != language {
            controller.language = language
        }
        controller.configuration = configuration
        updateHighlighting(controller, coordinator: context.coordinator)

        controller.reloadUI()
        return
    }

    private func updateHighlighting(_ controller: TextViewController, coordinator: Coordinator) {
        if !areHighlightProvidersEqual(controller: controller, coordinator: coordinator) {
            controller.setHighlightProviders(coordinator.highlightProviders)
        }
    }

    /// Checks if the controller needs updating.
    /// - Parameter controller: The controller to check.
    /// - Returns: True, if the controller's parameters should be updated.
    func paramsAreEqual(controller: NSViewControllerType, coordinator: Coordinator) -> Bool {
        controller.language.id == language.id &&
        controller.configuration == configuration &&
        areHighlightProvidersEqual(controller: controller, coordinator: coordinator)
    }

    private func areHighlightProvidersEqual(controller: TextViewController, coordinator: Coordinator) -> Bool {
        controller.highlightProviders.map { ObjectIdentifier($0) }
        == coordinator.highlightProviders.map { ObjectIdentifier($0) }
    }
}
