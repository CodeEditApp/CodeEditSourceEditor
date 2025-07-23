//
//  AutoCompleteCoordinatorProtocol.swift
//  CodeEditSourceEditor
//
//  Created by Abe Malla on 4/8/25.
//

public protocol AutoCompleteCoordinatorProtocol: TextViewCoordinator {
    func fetchCompletions() async throws -> [CodeSuggestionEntry]
    func showAutocompleteWindow()
}
