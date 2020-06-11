/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation
import UIKit

/// @mockable
protocol AboutViewControllable: ViewControllable {
    
}

final class AboutViewController: ViewController, AboutViewControllable, WebListener, UIAdaptivePresentationControllerDelegate {
    
    init(listener: AboutListener,
         webBuilder: WebBuildable) {
        self.listener = listener
        self.webBuilder = webBuilder
        
        super.init(nibName: nil, bundle: nil)
        
        title = "About the app"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UIAdaptivePresentationControllerDelegate
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        listener?.aboutRequestsDismissal(shouldHideViewController: false)
    }
    
    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = closeBarButtonItem
        
        loadWebView()
    }
    
    // MARK: - Private
    
    private func loadWebView() {
        guard webViewController == nil,
            let url = URL(string: "https://www.rijksoverheid.nl/onderwerpen/coronavirus-app/tijdpad-proces-coronavirus-app") else {
            return
        }
        
        let urlRequest = URLRequest(url: url)
        let webViewController = webBuilder.build(withListener: self,
                                                 urlRequest: urlRequest)
        self.webViewController = webViewController
        
        embed(childViewController: webViewController.uiviewController)
    }
    
    @objc
    func didTapClose() {
        listener?.aboutRequestsDismissal(shouldHideViewController: true)
    }
    
    private weak var listener: AboutListener?
    
    private let webBuilder: WebBuildable
    private var webViewController: ViewControllable?
    
    private lazy var closeBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close,
                                                          target: self,
                                                          action: #selector(didTapClose))
}
