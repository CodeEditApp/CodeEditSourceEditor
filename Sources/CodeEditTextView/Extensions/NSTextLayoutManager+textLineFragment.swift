//
//  File.swift
//  
//
//  Created by Khan Winter on 7/8/23.
//

import AppKit

extension NSTextLayoutManager {
    func textLineFragment(at location: NSTextLocation) -> NSTextLineFragment? {
        textLayoutFragment(for: location)?.textLineFragment(at: location)
    }
}

extension NSTextLayoutFragment {
    func textLineFragment(
        at location: NSTextLocation,
        in textContentManager: NSTextContentManager? = nil
    ) -> NSTextLineFragment? {
        guard let textContentManager = textContentManager ?? textLayoutManager?.textContentManager else {
            assertionFailure()
            return nil
        }

        let searchNSLocation = NSRange(NSTextRange(location: location), provider: textContentManager).location
        let fragmentLocation = NSRange(
            NSTextRange(location: rangeInElement.location),
            provider: textContentManager
        ).location
        return textLineFragments.first { lineFragment in
            let absoluteLineRange = NSRange(
                location: lineFragment.characterRange.location + fragmentLocation,
                length: lineFragment.characterRange.length
            )
            return absoluteLineRange.contains(searchNSLocation)
        }
    }
}
