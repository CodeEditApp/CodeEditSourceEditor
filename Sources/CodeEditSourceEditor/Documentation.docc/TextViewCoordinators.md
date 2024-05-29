# TextView Coordinators

Add advanced functionality to CodeEditSourceEditor.

## Overview

CodeEditSourceEditor provides an API to add more advanced functionality to the editor than SwiftUI allows. For instance, a 

### Make a Coordinator

To create a coordinator, first create a class that conforms to the ``TextViewCoordinator`` protocol.

```swift
class MyCoordinator {
    func prepareCoordinator(controller: TextViewController) { 
        // Do any setup, such as keeping a (weak) reference to the controller or adding a text storage delegate.
    }
}
```

Add any methods required for your coordinator to work, such as receiving notifications when text is edited, or 

```swift
class MyCoordinator {
    func prepareCoordinator(controller: TextViewController) { /* ... */ }

    func textViewDidChangeText(controller: TextViewController) {
        // Text was updated.
    }

    func textViewDidChangeSelection(controller: TextViewController, newPositions: [CursorPosition]) {
        // Selections were changed
    }
}
```

If your coordinator keeps any references to anything in CodeEditSourceEditor, make sure to dereference them using the ``TextViewCoordinator/destroy()-9nzfl`` method.

```swift
class MyCoordinator {
    func prepareCoordinator(controller: TextViewController) { /* ... */ }
    func textViewDidChangeText(controller: TextViewController) { /* ... */ }
    func textViewDidChangeSelection(controller: TextViewController, newPositions: [CursorPosition]) { /* ... */ }

    func destroy() {
        // Release any resources, `nil` any weak variables, remove delegates, etc.
    }
}
```

### Coordinator Lifecycle

A coordinator makes no assumptions about initialization, leaving the developer to pass any init parameters to the coordinator.

The lifecycle looks like this:
- Coordinator initialized (by user, not CodeEditSourceEditor).
- Coordinator given to CodeEditSourceEditor.
  - ``TextViewCoordinator/prepareCoordinator(controller:)`` is called.
- Events occur, coordinators are notified in the order they were passed to CodeEditSourceEditor.
- CodeEditSourceEditor is being closed.
  - ``TextViewCoordinator/destroy()-9nzfl`` is called.
  - CodeEditSourceEditor stops referencing the coordinator.

### Example

To see an example of a coordinator and they're use case, see the ``CombineCoordinator`` class. This class creates a coordinator that passes notifications on to a Combine stream.
