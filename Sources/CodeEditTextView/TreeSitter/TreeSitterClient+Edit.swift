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
    /// This class contains an edit state that can be resumed if a parser hits a timeout.
    class EditState {
        var edit: InputEdit
        var rangeSet: IndexSet
        var layerSet: Set<TSLanguageLayer>
        var touchedLayers: Set<TSLanguageLayer>
        var completion: ((IndexSet) -> Void)

        init(
            edit: InputEdit,
            minimumCapacity: Int = 0,
            completion: @escaping (IndexSet) -> Void
        ) {
            self.edit = edit
            self.rangeSet = IndexSet()
            self.layerSet = Set(minimumCapacity: minimumCapacity)
            self.touchedLayers = Set(minimumCapacity: minimumCapacity)
            self.completion = completion
        }
    }

    /// Applies the given edit to the current state and calls the editState's completion handler.
    /// - Parameters:
    ///   - editState: The edit state to apply.
    ///   - startAtLayerIndex: An optional layer index to start from if some work has already been done on this edit
    ///                        state object.
    ///   - runningAsync: Determine whether or not to timeout long running parse tasks.
    internal func applyEdit(editState: EditState, startAtLayerIndex: Int? = nil, runningAsync: Bool = false) {
        guard let readBlock, let textView, let state else { return }
        stateLock.lock()

        // Loop through all layers, apply edits & find changed byte ranges.
        let startIdx = startAtLayerIndex ?? 0
        for layerIdx in (startIdx..<state.layers.count).reversed() {
            let layer = state.layers[layerIdx]

            if layer.id != state.primaryLayer {
                // Reversed for safe removal while looping
                for rangeIdx in (0..<layer.ranges.count).reversed() {
                    layer.ranges[rangeIdx].applyInputEdit(editState.edit)

                    if layer.ranges[rangeIdx].length <= 0 {
                        layer.ranges.remove(at: rangeIdx)
                    }
                }
                if layer.ranges.isEmpty {
                    state.removeLanguageLayer(at: layerIdx)
                    continue
                }

                editState.touchedLayers.insert(layer)
            }

            layer.parser.includedRanges = layer.ranges.map { $0.tsRange }
            do {
                editState.rangeSet.insert(
                    ranges: try layer.findChangedByteRanges(
                        textView: textView,
                        edit: editState.edit,
                        timeout: runningAsync ? nil : Constants.parserTimeout,
                        readBlock: readBlock
                    )
                )
            } catch {
                // Timed out, queue an async edit with any data already computed.
                if !runningAsync {
                    applyEditAsync(editState: editState, startAtLayerIndex: layerIdx)
                }
                stateLock.unlock()
                return
            }

            editState.layerSet.insert(layer)
        }

        // Update the state object for any new injections that may have been caused by this edit.
        editState.rangeSet.formUnion(
            state.updateInjectedLayers(textView: textView, touchedLayers: editState.touchedLayers)
        )

        stateLock.unlock()
        if runningAsync {
            DispatchQueue.main.async {
                editState.completion(editState.rangeSet)
            }
        } else {
            editState.completion(editState.rangeSet)
        }
    }

    /// Enqueues the given edit state to be applied asynchronously.
    /// - Parameter editState: The edit state to enqueue.
    internal func applyEditAsync(editState: EditState, startAtLayerIndex: Int) {
        queuedEdits.append {
            self.applyEdit(editState: editState, startAtLayerIndex: startAtLayerIndex, runningAsync: true)
        }
        beginTasksIfNeeded()
    }
}
