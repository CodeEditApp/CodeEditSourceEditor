//
//  RangeStoreElement.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 5/28/25.
//

protocol RangeStoreElement: Equatable, Hashable {
    var isEmpty: Bool { get }
    func combineLowerPriority(_ other: Self?) -> Self
    func combineHigherPriority(_ other: Self?) -> Self
}
