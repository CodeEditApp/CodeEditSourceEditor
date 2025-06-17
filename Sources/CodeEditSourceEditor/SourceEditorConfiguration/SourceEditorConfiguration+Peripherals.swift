//
//  EditorConfig+Peripherals.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 6/16/25.
//

extension SourceEditorConfiguration {
    public struct Peripherals: Equatable {
        /// Whether to show the gutter.
        public var showGutter: Bool = true

        /// Whether to show the minimap.
        public var showMinimap: Bool

        /// Whether to show the reformatting guide.
        public var showReformattingGuide: Bool

        public init(
            showGutter: Bool = true,
            showMinimap: Bool = true,
            showReformattingGuide: Bool = false
        ) {
            self.showGutter = showGutter
            self.showMinimap = showMinimap
            self.showReformattingGuide = showReformattingGuide
        }

        @MainActor
        func didSetOnController(controller: TextViewController, oldConfig: Peripherals?) {
            var shouldUpdateInsets = false

            if oldConfig?.showGutter != showGutter {
                controller.gutterView.isHidden = !showGutter
                shouldUpdateInsets = true
            }

            if oldConfig?.showMinimap != showMinimap {
                controller.minimapView?.isHidden = !showMinimap
                shouldUpdateInsets = true
            }

            if oldConfig?.showReformattingGuide != showReformattingGuide {
                controller.reformattingGuideView.isHidden = !showReformattingGuide
                controller.reformattingGuideView.updatePosition(in: controller.textView)
            }

            if shouldUpdateInsets && controller.scrollView != nil { // Check for view existence
                controller.updateContentInsets()
                controller.updateTextInsets()
            }
        }
    }
}
