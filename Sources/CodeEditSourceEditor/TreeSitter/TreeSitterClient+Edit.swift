//
//  TreeSitterClient+Edit.swift
//  
//
//  Created by Khan Winter on 3/10/23.
//

import Foundation
import SwiftTreeSitter
import CodeEditLanguages

extension TreeSitterClient {
    /// Applies the given edit to the current state and calls the editState's completion handler.
    /// - Parameter edit: The edit to apply to the internal tree sitter state.
    /// - Returns: The set of ranges invalidated by the edit operation.
    func applyEdit(edit: InputEdit, editCounter: Int) -> IndexSet {
        guard let state, let readBlock, let readCallback else { return IndexSet() }
        let currentEditCounter = state.editCounter.value()
        let exitFast = currentEditCounter > editCounter

        var invalidatedRanges = IndexSet()
        var touchedLayers = Set<LanguageLayer>()

        // Loop through all layers, apply edits & find changed byte ranges.
        for (idx, layer) in state.layers.enumerated().reversed() {
            if layer.id != state.primaryLayer.id {
                // Reversed for safe removal while looping
                for rangeIdx in (0..<layer.ranges.count).reversed() {
                    layer.ranges[rangeIdx].applyInputEdit(edit)

                    if layer.ranges[rangeIdx].length <= 0 {
                        layer.ranges.remove(at: rangeIdx)
                    }
                }
                if layer.ranges.isEmpty {
                    state.removeLanguageLayer(at: idx)
                    continue
                }

                touchedLayers.insert(layer)
            }

            layer.parser.includedRanges = layer.ranges.map { $0.tsRange }
            let ranges = layer.findChangedByteRanges(
                edit: edit,
                timeout: Constants.parserTimeout,
                readBlock: readBlock,
                skipParse: exitFast
            )
            invalidatedRanges.insert(ranges: ranges)
        }

        // Update the state object for any new injections that may have been caused by this edit.
        if !exitFast {
            invalidatedRanges.formUnion(state.updateInjectedLayers(
                readCallback: readCallback,
                readBlock: readBlock,
                touchedLayers: touchedLayers
            ))
        }

        return invalidatedRanges
    }
}
