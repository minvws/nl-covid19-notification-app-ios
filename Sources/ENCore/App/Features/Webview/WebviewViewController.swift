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

private final class WebviewView: View {

    lazy var webView: WKWebView = {
        let webView = WKWebView()
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.allowsBackForwardNavigationGestures = false
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
}
