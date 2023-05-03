//
//  BracePairHighlight.swift
//  CodeEditTextView
//
//  Created by Khan Winter on 5/3/23.
//

/// An enum representing the type of highlight to use for brace pairs.
public enum BracePairHighlight {
    /// Highlight both the opening and closing character in a pair with a bounding box.
    /// The box will use the theme's text color with some opacity. The boxes will stay on screen until the cursor moves
    /// away from the brace pair.
    case box
    /// Flash a yellow highlight box on only the opposite character in the pair.
    /// This is closely matched to Xcode's flash highlight for brace pairs, and animates in and out over the course
    /// of `0.75` seconds.
    case flash
}
