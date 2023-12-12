//
//  TextViewController+TextViewDelegate.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 10/14/23.
//

import Foundation
import CodeEditTextView
import TextStory

extension TextViewController: TextViewDelegate {
    public func textView(_ textView: TextView, didReplaceContentsIn range: NSRange, with: String) {
        gutterView.needsDisplay = true
    }

    public func textView(_ textView: TextView, shouldReplaceContentsIn range: NSRange, with string: String) -> Bool {
        let mutation = TextMutation(
            string: string,
            range: range,
            limit: textView.textStorage.length
        )

        return shouldApplyMutation(mutation, to: textView)
    }
}
