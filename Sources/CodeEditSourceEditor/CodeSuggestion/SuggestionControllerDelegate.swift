//
//  SuggestionControllerDelegate.swift
//  CodeEditSourceEditor
//
//  Created by Abe Malla on 12/26/24.
//

import LanguageServerProtocol

public protocol SuggestionControllerDelegate: AnyObject {
    func applyCompletionItem(item: CompletionItem)
    func onClose()
    func onCompletion()
    func onCursorMove()
    func onItemSelect(item: CompletionItem)
}
