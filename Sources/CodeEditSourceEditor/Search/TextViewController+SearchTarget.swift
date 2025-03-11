//
//  File.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 3/11/25.
//

import CodeEditTextView

extension TextViewController: SearchTarget {
    var emphasizeAPI: EmphasizeAPI? {
        textView?.emphasizeAPI
    }
}
