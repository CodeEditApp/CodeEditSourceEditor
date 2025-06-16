//
//  EditorConfig+Behavior.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 6/16/25.
//

extension EditorConfig {
    public struct Behavior: Equatable {
        /// Controls whether the text view allows the user to edit text.
        public var isEditable: Bool = true

        /// Controls whether the text view allows the user to select text. If this value is true, and `isEditable` is
        /// false, the editor is selectable but not editable.
        public var isSelectable: Bool = true

        /// Determines what character(s) to insert when the tab key is pressed. Defaults to 4 spaces.
        public var indentOption: IndentOption = .spaces(count: 4)

        /// The column to reformat at.
        public var reformatAtColumn: Int

        public init(
            isEditable: Bool = true,
            isSelectable: Bool = true,
            indentOption: IndentOption = .spaces(count: 4),
            reformatAtColumn: Int
        ) {
            self.isEditable = isEditable
            self.isSelectable = isSelectable
            self.indentOption = indentOption
            self.reformatAtColumn = reformatAtColumn
        }
    }
}
