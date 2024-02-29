//
//  EditorTheme+Default.swift
//  CodeEditSourceEditorExample
//
//  Created by Khan Winter on 2/24/24.
//

import Foundation
import AppKit
import CodeEditSourceEditor

extension EditorTheme {
    static var standard: EditorTheme {
        EditorTheme(
            text: .init(hex: "000000"),
            insertionPoint: .init(hex: "000000"),
            invisibles: .init(hex: "D6D6D6"),
            background: .init(hex: "FFFFFF"),
            lineHighlight: .init(hex: "ECF5FF"),
            selection: .init(hex: "B2D7FF"),
            keywords: .init(hex: "9B2393"),
            commands: .init(hex: "326D74"),
            types: .init(hex: "0B4F79"),
            attributes: .init(hex: "815F03"),
            variables: .init(hex: "0F68A0"),
            values: .init(hex: "6C36A9"),
            numbers: .init(hex: "1C00CF"),
            strings: .init(hex: "C41A16"),
            characters: .init(hex: "1C00CF"),
            comments: .init(hex: "267507")
        )
    }
}
