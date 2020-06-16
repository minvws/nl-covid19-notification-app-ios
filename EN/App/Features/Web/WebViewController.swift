/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation
import UIKit

/// @mockable
protocol WebViewing {
    var uiview: UIView { get }
    
    func load(request: URLRequest)
}

/// @mockable
protocol WebViewControllable: ViewControllable {
    
}

final class WebViewController: ViewController, WebViewControllable {
    
    init(listener: WebListener,
         theme: Theme,
         webView: WebViewing,
         urlRequest: URLRequest) {
        self.listener = listener
        self.webView = webView
        self.urlRequest = urlRequest
        
        super.init(theme: theme)
    }
    
    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(webView.uiview)
        
        webView.uiview.translatesAutoresizingMaskIntoConstraints = false
        
        let constraints = [
            webView.uiview.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.uiview.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.uiview.topAnchor.constraint(equalTo: view.topAnchor),
            webView.uiview.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        
        if parent != nil {
            webView.load(request: urlRequest)
        }
    }
    
    // MARK: - Private
    
    private weak var listener: WebListener?
    private let webView: WebViewing
    private let urlRequest: URLRequest
}
