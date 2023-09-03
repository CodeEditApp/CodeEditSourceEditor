//
//  STTextViewController+STTextViewDelegate.swift
//  CodeEditTextView
//
//  Created by Khan Winter on 7/8/23.
//

import AppKit
import STTextView
import TextStory

extension STTextViewController {
//    public func undoManager(for textView: STTextView) -> UndoManager? {
//        textViewUndoManager.manager
//    }
//
//    public func textView(
//        _ textView: STTextView,
//        shouldChangeTextIn affectedCharRange: NSTextRange,
//        replacementString: String?
//    ) -> Bool {
//        guard let textContentStorage = textView.textContentStorage,
//              let range = affectedCharRange.nsRange(using: textContentStorage),
//              !textViewUndoManager.isUndoing,
//              !textViewUndoManager.isRedoing else {
//            return true
//        }
//
//        let mutation = TextMutation(
//            string: replacementString ?? "",
//            range: range,
//            limit: textView.textContentStorage?.length ?? 0
//        )
//
//        let result = shouldApplyMutation(mutation, to: textView)
//
//        if result {
//            textViewUndoManager.registerMutation(mutation)
//        }
//
//        return result
//    }
}
