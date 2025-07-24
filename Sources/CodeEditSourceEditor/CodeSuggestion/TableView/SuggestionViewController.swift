//
//  SuggestionViewController.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 7/22/25.
//

import AppKit
import SwiftUI
import Combine

class SuggestionViewController: NSViewController {
    var tableView: NSTableView!
    var scrollView: NSScrollView!
    var noItemsLabel: NSTextField!

    var itemObserver: AnyCancellable?

    weak var model: SuggestionViewModel? {
        didSet {
            itemObserver?.cancel()
            itemObserver = model?.$items.receive(on: DispatchQueue.main).sink { [weak self] _ in
                self?.onItemsUpdated()
            }
        }
    }

    override func loadView() {
        super.loadView()
        view.wantsLayer = true
        view.layer?.cornerRadius = 8.5
        view.layer?.backgroundColor = .clear

        tableView = NSTableView()
        configureTableView()
        scrollView = NSScrollView()
        configureScrollView()

        noItemsLabel = NSTextField(labelWithString: "No Completions")
        noItemsLabel.textColor = .secondaryLabelColor
        noItemsLabel.alignment = .center
        noItemsLabel.translatesAutoresizingMaskIntoConstraints = false
        noItemsLabel.isHidden = false

        view.addSubview(noItemsLabel)
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            noItemsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noItemsLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            noItemsLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10),

            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        resetScrollPosition()
        tableView.reloadData()
        if let controller = model?.activeTextView {
            styleView(using: controller)
        }
    }

    func styleView(using controller: TextViewController) {
        noItemsLabel.font = controller.font
        switch controller.systemAppearance {
        case .aqua:
            let color = controller.theme.background
            if color != .clear {
                let newColor = NSColor(
                    red: color.redComponent * 0.95,
                    green: color.greenComponent * 0.95,
                    blue: color.blueComponent * 0.95,
                    alpha: 1.0
                )
                view.layer?.backgroundColor = newColor.cgColor
            } else {
                view.layer?.backgroundColor = .clear
            }
        case .darkAqua:
            view.layer?.backgroundColor = controller.theme.background.cgColor
        default:
            return
        }

        guard model?.items.isEmpty == false else {
            let size = NSSize(width: 256, height: noItemsLabel.fittingSize.height + 20)
            preferredContentSize = size
            view.window?.setContentSize(size)
            view.window?.contentMinSize = size
            view.window?.contentMaxSize = size
            return
        }
        guard let rowView = tableView.view(atColumn: 0, row: 0, makeIfNecessary: true) else {
            return
        }
        let rowHeight = rowView.fittingSize.height

        let numberOfVisibleRows = min(CGFloat(model?.items.count ?? 0), SuggestionController.MAX_VISIBLE_ROWS)
        let newHeight = rowHeight * numberOfVisibleRows + SuggestionController.WINDOW_PADDING * 2

        let maxLength = min((model?.items.max(by: { $0.label.count < $1.label.count })?.label.count ?? 16) + 4, 48)
        let newWidth = CGFloat(maxLength) * controller.font.charWidth

        view.constraints.filter({ $0.firstAnchor == view.heightAnchor }).forEach { $0.isActive = false }
        view.heightAnchor.constraint(equalToConstant: newHeight).isActive = true

        preferredContentSize = NSSize(width: newWidth, height: newHeight)
        view.window?.setContentSize(NSSize(width: newWidth, height: newHeight))
        view.window?.contentMinSize = NSSize(width: newWidth, height: newHeight)
        view.window?.contentMaxSize = NSSize(width: .infinity, height: newHeight)
    }

    func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.headerView = nil
        tableView.backgroundColor = .clear
        tableView.intercellSpacing = .zero
        tableView.allowsEmptySelection = false
        tableView.selectionHighlightStyle = .regular
        tableView.style = .plain
        tableView.usesAutomaticRowHeights = true
        tableView.gridStyleMask = []
        tableView.target = self
        tableView.action = #selector(tableViewClicked(_:))
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("ItemsCell"))
        tableView.addTableColumn(column)
    }

    func configureScrollView() {
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.verticalScroller = NoSlotScroller()
        scrollView.scrollerStyle = .overlay
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.automaticallyAdjustsContentInsets = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.verticalScrollElasticity = .allowed
        scrollView.contentInsets = NSEdgeInsets(
            top: SuggestionController.WINDOW_PADDING,
            left: 0,
            bottom: SuggestionController.WINDOW_PADDING,
            right: 0
        )
    }

    func onItemsUpdated() {
        resetScrollPosition()
        if let model {
            noItemsLabel.isHidden = !model.items.isEmpty
            scrollView.isHidden = model.items.isEmpty
        }
        tableView.reloadData()
    }

    @objc private func tableViewClicked(_ sender: Any?) {
        if NSApp.currentEvent?.clickCount == 2 {
            applySelectedItem()
        }
    }

    private func resetScrollPosition() {
        let clipView = scrollView.contentView

        // Scroll to the top of the content
        clipView.scroll(to: NSPoint(x: 0, y: -SuggestionController.WINDOW_PADDING))

        // Select the first item
        if model?.items.isEmpty == false {
            tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        }
    }

    func applySelectedItem() {
        let row = tableView.selectedRow
        guard row >= 0, row < model?.items.count ?? 0 else {
            return
        }
        if let model {
            model.applySelectedItem(item: model.items[tableView.selectedRow], window: view.window)
        }
    }
}

extension SuggestionViewController: NSTableViewDataSource, NSTableViewDelegate {
    public func numberOfRows(in tableView: NSTableView) -> Int {
        model?.items.count ?? 0
    }

    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let model = model,
              row >= 0, row < model.items.count,
              let textView = model.activeTextView else {
            return nil
        }
        return NSHostingView(
            rootView: CodeSuggestionLabelView(
                suggestion: model.items[row],
                labelColor: textView.theme.text.color,
                secondaryLabelColor: textView.theme.comments.color,
                font: textView.font
            )
        )
    }

    public func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        CodeSuggestionRowView { [weak self] in
            self?.model?.activeTextView?.theme.background ?? NSColor.controlBackgroundColor
        }
    }

    public func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        // Only allow selection through keyboard navigation or single clicks
        NSApp.currentEvent?.type != .leftMouseDragged
    }

    public func tableViewSelectionDidChange(_ notification: Notification) {
        guard tableView.selectedRow >= 0 else { return }
        if let model {
            model.didSelect(item: model.items[tableView.selectedRow])
        }
    }
}
