//
//  ViewReuseQueue.swift
//  
//
//  Created by Khan Winter on 8/14/23.
//

import AppKit
import DequeModule

/// Maintains a queue of views available for reuse.
public class ViewReuseQueue<View: NSView, Key: Hashable> {
    /// A stack of views that are not currently in use
    public var queuedViews: Deque<View> = []

    /// Maps views that are no longer queued to the keys they're queued with.
    public var usedViews: [Key: View] = [:]

    public init() { }

    /// Finds, dequeues, or creates a view for the given key.
    ///
    /// If the view has been dequeued, it will return the view already queued for the given key it will be returned.
    /// If there was no view dequeued for the given key, the returned view will either be a view queued for reuse or a
    /// new view object.
    ///
    /// - Parameter key: The key for the view to find.
    /// - Returns: A view for the given key.
    public func getOrCreateView(forKey key: Key) -> View {
        let view: View
        if let usedView = usedViews[key] {
            view = usedView
        } else {
            view = queuedViews.popFirst() ?? View()
            view.prepareForReuse()
            usedViews[key] = view
        }
        return view
    }

    /// Removes a view for the given key and enqueues it for reuse.
    /// - Parameter key: The key for the view to reuse.
    public func enqueueView(forKey key: Key) {
        guard let view = usedViews[key] else { return }
        if queuedViews.count < usedViews.count / 4 {
            queuedViews.append(view)
        }
        usedViews.removeValue(forKey: key)
        view.removeFromSuperviewWithoutNeedingDisplay()
    }

    /// Enqueues all views not in the given set.
    /// - Parameter outsideSet: The keys who's views should not be enqueued for reuse.
    public func enqueueViews(notInSet keys: Set<Key>) {
        // Get all keys that are in "use" but not in the given set.
        for key in Set(usedViews.keys).subtracting(keys) {
            enqueueView(forKey: key)
        }
    }

    /// Enqueues all views keyed by the given set.
    /// - Parameter keys: The keys for all the views that should be enqueued.
    public func enqueueViews(in keys: Set<Key>) {
        for key in keys {
            enqueueView(forKey: key)
        }
    }

    deinit {
        usedViews.removeAll()
        queuedViews.removeAll()
    }
}
