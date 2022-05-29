# CodeEditTextView

> This is still work in progress and not yet implemented! Please don't submit PRs yet!

The Editor Text View for [`CodeEdit`](https://github.com/CodeEditApp/CodeEdit)

## Usage

```swift
import CodeEditTextView
import CodeLanguage

@State var text = "let x = 1.0"

CodeEditTextView(
    $text,
    language: .swift,
    theme: $theme,
    font: $font,
    tabWidth: .constant(4),
    lineHeight: .constant(1.2)
)
```
