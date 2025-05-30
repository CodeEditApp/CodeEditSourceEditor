//
//  FoldingRibbonView.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 5/6/25.
//

import Foundation
import AppKit
import CodeEditTextView
import Combine

#warning("Replace before release")
private let demoFoldProvider = IndentationLineFoldProvider()

/// Displays the code folding ribbon in the ``GutterView``.
///
/// This view draws its contents
class FoldingRibbonView: NSView {
    struct HoveringFold: Equatable {
        let range: ClosedRange<Int>
        let depth: Int
    }

    static let width: CGFloat = 7.0

    var model: LineFoldingModel

    // Disabling this lint rule because this initial value is required for @Invalidating
    @Invalidating(.display)
    var hoveringFold: HoveringFold? = nil // swiftlint:disable:this redundant_optional_initialization
    var hoverAnimationTimer: Timer?
    @Invalidating(.display)
    var hoverAnimationProgress: CGFloat = 0.0

    @Invalidating(.display)
    var backgroundColor: NSColor = NSColor.controlBackgroundColor

    @Invalidating(.display)
    var markerColor = NSColor(name: nil) { appearance in
        return switch appearance.name {
        case .aqua:
            NSColor(deviceWhite: 0.0, alpha: 0.1)
        case .darkAqua:
            NSColor(deviceWhite: 1.0, alpha: 0.2)
        default:
            NSColor()
        }
    }.cgColor

    @Invalidating(.display)
    var markerBorderColor = NSColor(name: nil) { appearance in
        return switch appearance.name {
        case .aqua:
            NSColor(deviceWhite: 1.0, alpha: 0.4)
        case .darkAqua:
            NSColor(deviceWhite: 0.0, alpha: 0.4)
        default:
            NSColor()
        }
    }.cgColor

    @Invalidating(.display)
    var hoverFillColor = NSColor(name: nil) { appearance in
        return switch appearance.name {
        case .aqua:
            NSColor(deviceWhite: 1.0, alpha: 1.0)
        case .darkAqua:
            NSColor(deviceWhite: 0.17, alpha: 1.0)
        default:
            NSColor()
        }
    }.cgColor

    @Invalidating(.display)
    var hoverBorderColor = NSColor(name: nil) { appearance in
        return switch appearance.name {
        case .aqua:
            NSColor(deviceWhite: 0.8, alpha: 1.0)
        case .darkAqua:
            NSColor(deviceWhite: 0.4, alpha: 1.0)
        default:
            NSColor()
        }
    }.cgColor

    private var foldUpdateCancellable: AnyCancellable?

    override public var isFlipped: Bool {
        true
    }

    init(textView: TextView, foldProvider: LineFoldProvider?) {
        #warning("Replace before release")
        self.model = LineFoldingModel(
            textView: textView,
            foldProvider: foldProvider ?? demoFoldProvider
        )
        super.init(frame: .zero)
        layerContentsRedrawPolicy = .onSetNeedsDisplay
        clipsToBounds = false

        foldUpdateCancellable = model.$foldCache.receive(on: RunLoop.main).sink { _ in
            self.needsDisplay = true
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        foldUpdateCancellable?.cancel()
    }

    override public func resetCursorRects() {
        // Don't use an iBeam in this view
        addCursorRect(bounds, cursor: .arrow)
    }

    // MARK: - Hover

    override func updateTrackingAreas() {
        trackingAreas.forEach(removeTrackingArea)
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseMoved, .activeInKeyWindow, .mouseEnteredAndExited],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
    }

    var attachments: [LineFoldPlaceholder] = []

    override func mouseDown(with event: NSEvent) {
        let clickPoint = convert(event.locationInWindow, from: nil)
        guard event.type == .leftMouseDown,
              let lineNumber = model.textView?.layoutManager.textLineForPosition(clickPoint.y)?.index,
              let fold = model.getCachedFoldAt(lineNumber: lineNumber) else {
            super.mouseDown(with: event)
            return
        }
//        if let attachment = model.textView?.layoutManager.attachments.getAttachmentsStartingIn(fold.range.range).first {
//            model.textView?.layoutManager.attachments.remove(atOffset: attachment.range.location)
//            fold.range.collapsed = false
//            attachments.removeAll(where: { $0 === attachment.attachment })
//        } else {
//            let placeholder = LineFoldPlaceholder()
//            model.textView?.layoutManager.attachments.add(placeholder, for: fold.range.range)
//            attachments.append(placeholder)
//            fold.range.collapsed = true
//        }

        model.textView?.needsLayout = true
    }

    override func mouseMoved(with event: NSEvent) {
//        let pointInView = convert(event.locationInWindow, from: nil)
//        guard let lineNumber = model.textView?.layoutManager.textLineForPosition(pointInView.y)?.index,
//              let fold = model.getCachedFoldAt(lineNumber: lineNumber) else {
//            hoverAnimationProgress = 0.0
//            hoveringFold = nil
//            return
//        }
//
//        let newHoverRange = HoveringFold(range: fold.range.lineRange, depth: fold.depth)
//        guard newHoverRange != hoveringFold else {
//            return
//        }
//        hoverAnimationTimer?.invalidate()
//        // We only animate the first hovered fold. If the user moves the mouse vertically into other folds we just
//        // show it immediately.
//        if hoveringFold == nil {
//            hoverAnimationProgress = 0.0
//            hoveringFold = newHoverRange
//
//            let duration: TimeInterval = 0.2
//            let startTime = CACurrentMediaTime()
//            hoverAnimationTimer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { [weak self] timer in
//                guard let self = self else { return }
//                let now = CACurrentMediaTime()
//                let time = CGFloat((now - startTime) / duration)
//                self.hoverAnimationProgress = min(1.0, time)
//                if self.hoverAnimationProgress >= 1.0 {
//                    timer.invalidate()
//                }
//            }
//            return
//        }
//
//        // Don't animate these
//        hoverAnimationProgress = 1.0
//        hoveringFold = newHoverRange
    }

    override func mouseExited(with event: NSEvent) {
        hoverAnimationProgress = 0.0
        hoveringFold = nil
    }
}
