//
//  IndentOption.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 3/26/23.
//

/// Represents what to insert on a tab key press.
public enum IndentOption: Equatable {
    case spaces(count: Int)
    case tab

    var stringValue: String {
        switch self {
        case .spaces(let count):
            return String(repeating: " ", count: count)
        case .tab:
            return "\t"
        }
    }

    public static func == (lhs: IndentOption, rhs: IndentOption) -> Bool {
        switch (lhs, rhs) {
        case (.tab, .tab):
            return true
        case (.spaces(let lhsCount), .spaces(let rhsCount)):
            return lhsCount == rhsCount
        default:
            return false
        }
    }
}
