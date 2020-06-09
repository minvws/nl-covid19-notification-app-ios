/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

/// @mockable
protocol WebViewControllable: ViewControllable {
    
}

final class WebViewController: ViewController, WebViewControllable {
    
    init(listener: WebListener, urlRequest: URLRequest) {
        self.listener = listener
        self.urlRequest = urlRequest
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - ViewController Lifecycle
    
    override func loadView() {
        self.view = internalView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TODO: Implement or delete
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isMovingFromParent {
            listener?.webRequestsDismissal(shouldHideViewController: false)
        }
    }
    
    // MARK: - Private
    
    private weak var listener: WebListener?
    private lazy var internalView: WebView = WebView()
    private let urlRequest: URLRequest
}

private final class WebView: View {
    override func build() {
        super.build()
        
        // TODO: Construct View here or delete this function
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        
        // TODO: Setup constraints here or delete this function
    }
}
