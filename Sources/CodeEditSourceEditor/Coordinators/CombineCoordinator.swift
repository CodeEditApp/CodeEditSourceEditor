//
//  CombineCoordinator.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 5/19/24.
//

import Foundation
import Combine
import CodeEditTextView

public class CombineCoordinator: TextViewCoordinator {
    public let updateSubject: PassthroughSubject<[NSRange], Never> = .init()
    public let selectionSubject: CurrentValueSubject<[CursorPosition], Never> = .init([])

    public init() { }

    public func prepareCoordinator(controller: TextViewController) { }

    public func textViewDidChangeText(controller: TextViewController, editedRanges: [NSRange]) {
        updateSubject.send(editedRanges)
    }

    public func textViewDidChangeSelection(controller: TextViewController, newPositions: [CursorPosition]) {
        selectionSubject.send(newPositions)
    }

    public func destroy() {
        updateSubject.send(completion: .finished)
        selectionSubject.send(completion: .finished)
    }
}
