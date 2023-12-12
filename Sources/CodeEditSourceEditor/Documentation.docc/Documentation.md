# ``CodeEditSourceEditor``

A code editor with syntax highlighting powered by tree-sitter. 

## Overview

![logo](codeedittextview-logo)

An Xcode-inspired code editor view written in Swift powered by tree-sitter for [CodeEdit](https://github.com/CodeEditApp/CodeEdit). Features include syntax highlighting (based on the provided theme), code completion, find and replace, text diff, validation, current line highlighting, minimap, inline messages (warnings and errors), bracket matching, and more.

This package includes both `AppKit` and `SwiftUI` components. It also relies on the `CodeEditLanguages` and `Theme` module. 

![banner](preview)

## Syntax Highlighting

``CodeEditSourceEditor`` uses `tree-sitter` for syntax highlighting. A list of already supported languages can be found [here](https://github.com/CodeEditApp/CodeEditSourceEditor/issues/15).

New languages need to be added to the [CodeEditLanguages](https://github.com/CodeEditApp/CodeEditLanguages) repo.

## Dependencies

Special thanks to both [Marcin Krzyzanowski](https://twitter.com/krzyzanowskim) & [Matt Massicotte](https://twitter.com/mattie) for the great work they've done!

| Package | Source | Author |
| - | - | - |
| `STTextView` | [GitHub](https://github.com/krzyzanowskim/STTextView) | [Marcin Krzyzanowski](https://twitter.com/krzyzanowskim) |
| `SwiftTreeSitter` | [GitHub](https://github.com/ChimeHQ/SwiftTreeSitter) | [Matt Massicotte](https://twitter.com/mattie) |

## Topics

### Text View

- ``CodeEditSourceEditor/CodeEditSourceEditor``
- ``CodeEditSourceEditor/TextViewController``

### Theme

- ``EditorTheme``
