//
//  TextViewController.swift
//  
//
//  Created by Khan Winter on 6/25/23.
//

import AppKit

public class TextViewController: NSViewController {
    var scrollView: NSScrollView!
    var textView: TextView!

    var string: String

    init(string: String) {
        self.string = string
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        scrollView = NSScrollView()
        textView = TextView(string: string)
//        textView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalRuler = true
        scrollView.documentView = textView
        scrollView.automaticallyAdjustsContentInsets = false
        scrollView.contentInsets = NSEdgeInsets(top: 128, left: 0, bottom: 32, right: 0)

        self.view = scrollView

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
