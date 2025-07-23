//
//  AutoCompleteCoordinatorProtocol.swift
//  CodeEditSourceEditor
//
//  Created by Abe Malla on 4/8/25.
//

import LanguageServerProtocol

public protocol AutoCompleteCoordinatorProtocol: TextViewCoordinator {
    func fetchCompletions() async throws -> [CompletionItem]
    func showAutocompleteWindow()
}
