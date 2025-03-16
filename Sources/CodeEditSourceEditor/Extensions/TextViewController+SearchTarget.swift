//
//  TextViewController.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 3/11/25.
//

import CodeEditTextView

extension TextViewController: FindTarget {
    var emphasizeAPI: EmphasizeAPI? {
        textView?.emphasizeAPI
    }
}
