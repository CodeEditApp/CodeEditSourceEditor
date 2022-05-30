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

- C
- CSS
- Go 
- HTML
- Java
- JSON
- Python
- Ruby
- Rust
- Swift
- YAML

## Topics

### Instance Properties

- ``id``
- ``displayName``
- ``extensions``
- ``queryURL``
- ``language``

### Type Properties

- ``knownLanguages``
- ``default``
- ``c``
- ``css``
- ``go``
- ``goMod``
- ``html``
- ``java``
- ``json``
- ``python``
- ``ruby``
- ``rust``
- ``swift``
- ``yaml``

### Type Methods

- ``detectLanguageFrom(url:)``
