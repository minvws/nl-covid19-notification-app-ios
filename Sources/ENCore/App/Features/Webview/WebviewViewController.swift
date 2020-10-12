/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import UIKit
import WebKit

final class WebviewViewController: ViewController, Logging, UIAdaptivePresentationControllerDelegate, WebviewViewDelegate {

    init(listener: WebviewListener, url: URL, theme: Theme) {
        self.listener = listener
        self.initialURL = url

        super.init(theme: theme)

        navigationItem.rightBarButtonItem = closeBarButtonItem
        presentationController?.delegate = self
    }

    // MARK: - ViewController Lifecycle

    override func loadView() {
        self.view = internalView
        self.view.frame = UIScreen.main.bounds
        internalView.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if webViewLoadingEnabled() {
            internalView.webView.load(URLRequest(url: initialURL))
        } else {
            logDebug("`webViewLoading` disabled")
        }
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        listener?.webviewRequestsDismissal(shouldHideViewController: false)
    }

    @objc func didTapClose() {
        listener?.webviewRequestsDismissal(shouldHideViewController: true)
    }

    // MARK: - WebviewViewDelegate

    fileprivate func webView(_ webView: WebviewView, didClickLink linkURL: URL) {
        if UIApplication.shared.canOpenURL(linkURL) {
            UIApplication.shared.open(linkURL, options: [:], completionHandler: nil)
        } else {
            logError("Unable to open \(linkURL)")
        }
    }

    // MARK: - Private

    private lazy var internalView: WebviewView = WebviewView(theme: theme)
    private weak var listener: WebviewListener?
    private let initialURL: URL
    private lazy var closeBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close,
                                                          target: self,
                                                          action: #selector(didTapClose))
}

private protocol WebviewViewDelegate: AnyObject {
    func webView(_ webView: WebviewView, didClickLink withURL: URL)
}

private final class WebviewView: View, WKNavigationDelegate {

    weak var delegate: WebviewViewDelegate?

    lazy var webView: WKWebView = {
        let webView = WKWebView()
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.allowsBackForwardNavigationGestures = false
        webView.navigationDelegate = self
        return webView
    }()

    private lazy var gradientImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .clear
        imageView.image = .gradient ?? UIImage()
        return imageView
    }()

    override func build() {
        super.build()
        addSubview(webView)
        addSubview(gradientImageView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        webView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        gradientImageView.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.height.equalTo(25)
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> ()) {

        if navigationAction.navigationType == .linkActivated,
            let url = navigationAction.request.url,
            let delegate = delegate {

            delegate.webView(self, didClickLink: url)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }
}
