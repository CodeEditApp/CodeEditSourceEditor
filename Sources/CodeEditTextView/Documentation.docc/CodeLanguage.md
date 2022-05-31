# ``CodeEditTextView/CodeLanguage``

## Overview

If the language required is known they can be accessed by using the type properties below.

```swift
let language = CodeLanguage.swift
```

If the language needs to be discovered by the file extension this can be done by calling ``detectLanguageFrom(url:)``.

```swift
let fileURL = URL(fileURLWithPath: "/path/to/file.swift")
let language = CodeLanguage.detectLanguageFrom(url: fileURL)
```

> In case the language is not supported yet, the resulting ``CodeLanguage`` will be ``default`` (plain text).

### Supported Languages

- Bash
- C
- C++
- C#
- CSS
- Go
- Go Mod
- HTML
- Java
- JavaScript
- JSON
- JSX
- PHP
- Python
- Ruby
- Rust
- Swift
- YAML

## Topics

### Instance Properties

- ``id``
- ``tsName``
- ``extensions``
- ``parentQueryURL``
- ``tsName``
- ``queryURL``
- ``language``
- ``additionalHighlights``

### Type Properties

- ``allLanguages``
- ``default``
- ``bash``
- ``c``
- ``cpp``
- ``cSharp``
- ``css``
- ``go``
- ``goMod``
- ``html``
- ``java``
- ``javascript``
- ``json``
- ``jsx``
- ``php``
- ``python``
- ``ruby``
- ``rust``
- ``swift``
- ``yaml``

### Type Methods

- ``detectLanguageFrom(url:)``
