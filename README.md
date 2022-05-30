![Github Tests](https://img.shields.io/github/workflow/status/CodeEditApp/CodeEditTextView/tests/main?label=tests&style=flat-square)
![Documentation](https://img.shields.io/github/workflow/status/CodeEditApp/CodeEditTextView/build-documentation/main?label=docs)
![GitHub Repo stars](https://img.shields.io/github/stars/CodeEditApp/CodeEditTextView?style=flat-square)
![GitHub forks](https://img.shields.io/github/forks/CodeEditApp/CodeEditTextView?style=flat-square)
[![Discord Badge](https://img.shields.io/discord/951544472238444645?color=5865F2&label=Discord&logo=discord&logoColor=white&style=flat-square)](https://discord.gg/vChUXVf9Em)

# CodeEditTextView

The Editor Text View for [`CodeEdit`](https://github.com/CodeEditApp/CodeEdit)

> This is currently only implemented in the [`feature/new-editor`](https://github.com/CodeEditApp/CodeEdit/tree/feature/new-editor) branch!

## Documentation

This package is fully documented. Check out the documentation [here](https://codeeditapp.github.io/CodeEditTextView/documentation/codeedittextview/)!

## Usage

```swift
import CodeEditTextView

struct ContentView: View {

    @State var text = "let x = 1.0"
    @State var theme = EditorTheme(...)
    @State var font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
    @State var tabWidth = 4
    @State var lineHeight = 1.2

    var body: some View { 
        CodeEditTextView(
            $text,
            language: .swift,
            theme: $theme,
            font: $font,
            tabWidth: $tabWidth,
            lineHeight: $lineHeight
        )
    }
}
```

## Currently Supported Languages
- CSS
- Go
- HTML
- Java
- JSON
- Python
- Ruby
- Swift
- YAML

## Dependencies

Special thanks to both [Marcin Krzyzanowski](https://twitter.com/krzyzanowskim) & [Matt Massicotte](https://twitter.com/mattie) for the great work they've done!

| Package | Source | Author |
| :- | :- | :- |
| `STTextView` | [GitHub](https://github.com/krzyzanowskim/STTextView) | [Marcin Krzyzanowski](https://twitter.com/krzyzanowskim) |
| `SwiftTreeSitter` | [GitHub](https://github.com/ChimeHQ/SwiftTreeSitter) | [Matt Massicotte](https://twitter.com/mattie) |
