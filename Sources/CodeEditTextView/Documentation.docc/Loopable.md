# ``CodeEditTextView/Loopable``

## Overview

```swift
struct Author: Loopable {
    var name: String = "Steve"
    var books: Int = 4
}

let author = Author()
print(author.allProperties())

// returns
["name": "Steve", "books": 4]
```

## Topics

### Instance Methods

- ``allProperties()``
