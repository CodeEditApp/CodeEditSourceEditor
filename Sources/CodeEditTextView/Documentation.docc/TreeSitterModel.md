# ``CodeEditTextView/TreeSitterModel``

## Overview

Since fetching queries *can* be expensive the queries are fetched lazily and kept in memory for the entire session.

> Be aware that running the application in `Debug` configuration will lead to worse performance. Make sure to run it in `Release` configuration.

## Usage

```swift
let language = CodeLanguage.swift

// this call might be expensive
let query = TreeSitterModel.shared.query(for: language.id)
```
Or access it directly
```swift
// this call might be expensive
let query = TreeSitterModel.shared.swiftQuery
```

## Topics

### Type Properties

- ``shared``

### Instance Methods

- ``query(for:)``

### Instance Properties

- ``bashQuery``
- ``cQuery``
- ``cppQuery``
- ``cSharpQuery``
- ``cssQuery``
- ``goQuery``
- ``goModQuery``
- ``htmlQuery``
- ``javaQuery``
- ``javascriptQuery``
- ``jsonQuery``
- ``jsxQuery``
- ``phpQuery``
- ``pythonQuery``
- ``rubyQuery``
- ``rustQuery``
- ``swiftQuery``
- ``yamlQuery``
