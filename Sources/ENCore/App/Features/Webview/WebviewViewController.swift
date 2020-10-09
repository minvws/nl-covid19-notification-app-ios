/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import UIKit
import WebKit

final class WebviewViewController: ViewController, Logging, UIAdaptivePresentationControllerDelegate {

    init(listener: WebviewListener, url: URL, theme: Theme) {
        self.listener = listener
        self.url = url

        super.init(theme: theme)

        navigationItem.rightBarButtonItem = closeBarButtonItem
        presentationController?.delegate = self
    }

    // MARK: - ViewController Lifecycle

    override func loadView() {
        self.view = internalView
        self.view.frame = UIScreen.main.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if webViewLoadingEnabled() {
            internalView.webView.load(URLRequest(url: url))
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

    // MARK: - Private

    private lazy var internalView: WebviewView = WebviewView(theme: theme)
    private weak var listener: WebviewListener?
    private let url: URL
    private lazy var closeBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close,
                                                          target: self,
                                                          action: #selector(didTapClose))
}

private final class WebviewView: View, WKNavigationDelegate {

    lazy var webView: WKWebView = {
        let webView = WKWebView()
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.allowsBackForwardNavigationGestures = false
        webView.navigationDelegate = self
        return webView
    }()

    private lazy var errorView: ErrorView = {
        let errorView = ErrorView(theme: theme)
        errorView.translatesAutoresizingMaskIntoConstraints = false
        return errorView
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
        addSubview(errorView)

        errorView.isHidden = true
    }

    override func setupConstraints() {
        super.setupConstraints()

        webView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        errorView.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        gradientImageView.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.height.equalTo(25)
        }
    }

    private func showError(show: Bool) {
        webView.isHidden = show
        gradientImageView.isHidden = show
        errorView.isHidden = !show
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        showError(show: true)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showError(show: true)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        showError(show: false)
    }
}

private final class ErrorView: View {

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.alpha = 0.5
        imageView.image = .warning
        return imageView
    }()

    override func build() {
        super.build()
        addSubview(imageView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        imageView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
            maker.width.equalTo(100)
            maker.height.equalTo(100)
        }
    }
}
