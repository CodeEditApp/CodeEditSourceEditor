//
//  CaptureModifiers.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 10/24/24.
//

// https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#semanticTokenModifiers

public enum CaptureModifiers: Int8, CaseIterable, Sendable {
    case declaration
    case definition
    case readonly
    case `static`
    case deprecated
    case abstract
    case async
    case modification
    case documentation
    case defaultLibrary
}

extension CaptureModifiers: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .declaration: return "declaration"
        case .definition: return "definition"
        case .readonly: return "readonly"
        case .static: return "static"
        case .deprecated: return "deprecated"
        case .abstract: return "abstract"
        case .async: return "async"
        case .modification: return "modification"
        case .documentation: return "documentation"
        case .defaultLibrary: return "defaultLibrary"
        }
    }
}

/// A set of capture modifiers, efficiently represented by a single integer.
public struct CaptureModifierSet: OptionSet, Equatable, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    static let declaration = CaptureModifierSet(rawValue: 1 << CaptureModifiers.declaration.rawValue)
    static let definition = CaptureModifierSet(rawValue: 1 << CaptureModifiers.definition.rawValue)
    static let readonly = CaptureModifierSet(rawValue: 1 << CaptureModifiers.readonly.rawValue)
    static let `static` = CaptureModifierSet(rawValue: 1 << CaptureModifiers.static.rawValue)
    static let deprecated = CaptureModifierSet(rawValue: 1 << CaptureModifiers.deprecated.rawValue)
    static let abstract = CaptureModifierSet(rawValue: 1 << CaptureModifiers.abstract.rawValue)
    static let async = CaptureModifierSet(rawValue: 1 << CaptureModifiers.async.rawValue)
    static let modification = CaptureModifierSet(rawValue: 1 << CaptureModifiers.modification.rawValue)
    static let documentation = CaptureModifierSet(rawValue: 1 << CaptureModifiers.documentation.rawValue)
    static let defaultLibrary = CaptureModifierSet(rawValue: 1 << CaptureModifiers.defaultLibrary.rawValue)

    /// All values in the set.
    var values: [CaptureModifiers] {
        var rawValue = self.rawValue
        var values: [Int8] = []
        while rawValue > 0 {
            values.append(Int8(rawValue.trailingZeroBitCount))
            rawValue &= ~UInt(1 << rawValue.trailingZeroBitCount)
        }
        return values.compactMap({ CaptureModifiers(rawValue: $0) })
    }
}
