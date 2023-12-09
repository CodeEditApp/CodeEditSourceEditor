//
//  TextView+Drag.swift
//
//
//  Created by Khan Winter on 10/20/23.
//

import AppKit

extension TextView: NSDraggingSource {
    class DragSelectionGesture: NSPressGestureRecognizer {
        override func mouseDown(with event: NSEvent) {
            guard isEnabled, let view = self.view as? TextView, event.type == .leftMouseDown else {
                return
            }

            let clickPoint = view.convert(event.locationInWindow, from: nil)
            let selectionRects = view.selectionManager.textSelections.filter({ !$0.range.isEmpty }).flatMap {
                view.selectionManager.getFillRects(in: view.frame, for: $0)
            }
            if !selectionRects.contains(where: { $0.contains(clickPoint) }) {
                state = .failed
            }

            super.mouseDown(with: event)
        }
    }

    func setUpDragGesture() {
        let dragGesture = DragSelectionGesture(target: self, action: #selector(dragGestureHandler(_:)))
        dragGesture.minimumPressDuration = NSEvent.doubleClickInterval / 3
        dragGesture.isEnabled = isSelectable
        addGestureRecognizer(dragGesture)
    }

    @objc private func dragGestureHandler(_ sender: Any) {
        let selectionRects = selectionManager.textSelections.filter({ !$0.range.isEmpty }).flatMap {
            selectionManager.getFillRects(in: frame, for: $0)
        }
        // TODO: This SUcks
        let minX = selectionRects.min(by: { $0.minX < $1.minX })?.minX ?? 0.0
        let minY = selectionRects.min(by: { $0.minY < $1.minY })?.minY ?? 0.0
        let maxX = selectionRects.max(by: { $0.maxX < $1.maxX })?.maxX ?? 0.0
        let maxY = selectionRects.max(by: { $0.maxY < $1.maxY })?.maxY ?? 0.0
        let imageBounds = CGRect(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        )

        guard let bitmap = bitmapImageRepForCachingDisplay(in: imageBounds) else {
            return
        }

        selectionRects.forEach { selectionRect in
            self.cacheDisplay(in: selectionRect, to: bitmap)
        }

        let draggingImage = NSImage(cgImage: bitmap.cgImage!, size: imageBounds.size)

        let attributedString = selectionManager
            .textSelections
            .sorted(by: { $0.range.location < $1.range.location })
            .map { textStorage.attributedSubstring(from: $0.range) }
            .reduce(NSMutableAttributedString(), { $0.append($1); return $0 })
        let draggingItem = NSDraggingItem(pasteboardWriter: attributedString)
        draggingItem.setDraggingFrame(imageBounds, contents: draggingImage)

        beginDraggingSession(with: [draggingItem], event: NSApp.currentEvent!, source: self)
    }

    public func draggingSession(
        _ session: NSDraggingSession,
        sourceOperationMaskFor context: NSDraggingContext
    ) -> NSDragOperation {
        context == .outsideApplication ? .copy : .move
    }
}
