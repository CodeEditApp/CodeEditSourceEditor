![Github Tests](https://img.shields.io/github/workflow/status/CodeEditApp/CodeEditTextView/tests/main?label=tests&style=flat-square)
![Documentation](https://img.shields.io/github/workflow/status/CodeEditApp/CodeEditTextView/build-documentation/main?label=docs&style=flat-square)
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
- [ ] Agda
- [ ] Bash
- [x] [C](https://github.com/tree-sitter/tree-sitter-c)
- [x] [C++](https://github.com/tree-sitter/tree-sitter-cpp)
- [x] [C#](https://github.com/tree-sitter/tree-sitter-c-sharp)
- [ ] CodeQL
- [x] [CSS](https://github.com/lukepistrol/tree-sitter-css)
- [ ] Embedded template (ERB, EJS)
- [x] [Go](https://github.com/tree-sitter/tree-sitter-go)
- [ ] Haskell
- [x] [HTML](https://github.com/mattmassicotte/tree-sitter-html)
- [x] [Java](https://github.com/tree-sitter/tree-sitter-java)
- [x] [JavaScript/JSX](https://github.com/tree-sitter/tree-sitter-javascript)
- [ ] JSDoc
- [x] [JSON](https://github.com/mattmassicotte/tree-sitter-json)
- [ ] Julia
- [ ] OCaml
- [ ] Markdown
- [x] Plain Text
- [ ] Perl
- [x] [PHP](https://github.com/tree-sitter/tree-sitter-php)
- [x] [Python](https://github.com/lukepistrol/tree-sitter-python)
- [ ] Regex
- [x] [Ruby](https://github.com/mattmassicotte/tree-sitter-ruby)
- [x] [Rust](https://github.com/tree-sitter/tree-sitter-rust)
- [ ] Scala
- [ ] Sql
- [x] [Swift](https://github.com/mattmassicotte/tree-sitter-swift)
- [ ] Toml
- [ ] TypeScript
- [ ] Verilog
- [x] [YAML](https://github.com/mattmassicotte/tree-sitter-yaml)

## Dependencies

Special thanks to both [Marcin Krzyzanowski](https://twitter.com/krzyzanowskim) & [Matt Massicotte](https://twitter.com/mattie) for the great work they've done!

| Package | Source | Author |
| :- | :- | :- |
| `STTextView` | [GitHub](https://github.com/krzyzanowskim/STTextView) | [Marcin Krzyzanowski](https://twitter.com/krzyzanowskim) |
| `SwiftTreeSitter` | [GitHub](https://github.com/ChimeHQ/SwiftTreeSitter) | [Matt Massicotte](https://twitter.com/mattie) |
