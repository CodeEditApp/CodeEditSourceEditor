//
//  SuggestionControllerDelegate.swift
//  CodeEditSourceEditor
//
//  Created by Abe Malla on 12/26/24.
//

public protocol SuggestionControllerDelegate: AnyObject {
    var currentFilterText: String { get }

    func applyCompletionItem(item: CodeSuggestionEntry)
    func onClose()
    func onCompletion()
    func onCursorMove()
    func onItemSelect(item: CodeSuggestionEntry)
}
