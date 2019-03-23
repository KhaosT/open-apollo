//
//  WebViewController.swift
//  Apollo
//
//  Created by Khaos Tian on 11/4/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: BaseViewController {

    private var observationContext = 0
    private let initialURL: URL
    
    private lazy var webView: WKWebView = {
        let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.title), options: .new, context: &observationContext)
        return webView
    }()
    
    required init(url: URL, title: String?) {
        self.initialURL = url
        super.init()
        self.title = title
    }
    
    deinit {
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.title))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate(
            [
                webView.topAnchor.constraint(equalTo: view.topAnchor),
                webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ]
        )
        
        webView.load(URLRequest(url: initialURL))
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &observationContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        let object = object as AnyObject
        guard object === webView, keyPath == #keyPath(WKWebView.title) else {
            return
        }
        
        DispatchQueue.main.async {
            self.title = self.webView.title
        }
    }
}
