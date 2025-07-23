//
//  SuggestionViewController.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 7/22/25.
//

import AppKit
import Combine

class SuggestionViewController: NSViewController {
    var tableView: NSTableView!
    var scrollView: NSScrollView!
    var tintView: NSView!
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
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        tintView = NSView()
        tintView.translatesAutoresizingMaskIntoConstraints = false
        tintView.wantsLayer = true
        tintView.layer?.cornerRadius = 8.5
        view.addSubview(tintView)

        tableView = NSTableView()
        configureTableView()
        scrollView = NSScrollView()
        configureScrollView()

        noItemsLabel = NSTextField(labelWithString: "No Completions")
        noItemsLabel.textColor = .secondaryLabelColor
        noItemsLabel.alignment = .center
        noItemsLabel.translatesAutoresizingMaskIntoConstraints = false
        noItemsLabel.isHidden = false
        // TODO: GET FONT SIZE FROM THEME
        noItemsLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)

        tintView.addSubview(noItemsLabel)
        tintView.addSubview(scrollView)

        NSLayoutConstraint.activate([
            tintView.topAnchor.constraint(equalTo: view.topAnchor),
            tintView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tintView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tintView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            noItemsLabel.centerXAnchor.constraint(equalTo: tintView.centerXAnchor),
            noItemsLabel.centerYAnchor.constraint(equalTo: tintView.centerYAnchor),
            scrollView.topAnchor.constraint(equalTo: tintView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: tintView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: tintView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: tintView.bottomAnchor)
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
                tintView.layer?.backgroundColor = newColor.cgColor
            } else {
                tintView.layer?.backgroundColor = .clear
            }
        case .darkAqua:
            tintView.layer?.backgroundColor = controller.theme.background.cgColor
        default:
            return
        }
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
        tableView.usesAutomaticRowHeights = false
        tableView.rowSizeStyle = .custom
        tableView.rowHeight = 21
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
        if !(model?.items.isEmpty ?? true) {
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
        guard row >= 0, row < model?.items.count ?? 0 else { return nil }
        return model?.items[row].view
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
