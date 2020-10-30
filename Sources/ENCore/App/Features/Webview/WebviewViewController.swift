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
//            internalView.webView.load(URLRequest(url: url))
            internalView.webView.load(URLRequest(url: URL(string: "http://www.bsdfsdfsdfsfsd.hl")!))
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
        errorView.actionButton.addTarget(self, action: #selector(didTapReloadButton(sender:)), for: .touchUpInside)
        return errorView
    }()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
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
        addSubview(activityIndicator)

        errorView.isHidden = true
    }

    override func setupConstraints() {
        super.setupConstraints()

        webView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        errorView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        gradientImageView.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.height.equalTo(25)
        }

        activityIndicator.snp.makeConstraints { maker in
            maker.height.width.equalTo(40)
            maker.center.equalToSuperview()
        }
    }

    private func loadingFinished(withError hasError: Bool) {
        webView.isHidden = hasError
        errorView.isHidden = !hasError
        activityIndicator.stopAnimating()
    }

    private func loadingStarted() {
        webView.isHidden = true
        errorView.isHidden = true
        activityIndicator.startAnimating()
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        loadingStarted()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        loadingFinished(withError: true)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        loadingFinished(withError: true)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingFinished(withError: false)
    }

    // MARK: - Private

    @objc private func didTapReloadButton(sender: Button) {
        webView.reload()
    }
}

private final class ErrorView: View {

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 32
        stackView.alignment = .center

        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)

        return stackView
    }()

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = .loadingError
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var titleLabel: Label = {
        let label = Label()
        label.text = "Deze pagina kan niet geladen worden"
        label.font = theme.fonts.title2
        label.accessibilityTraits = .header
        label.numberOfLines = 0
        return label
    }()

    private lazy var subtitleLabel: Label = {
        let label = Label()
        label.text = "Er gaat iets mis hier. Kom later terug of probeer de pagina opnieuw te laden"
        label.font = theme.fonts.body
        label.accessibilityTraits = .staticText
        label.numberOfLines = 0
        return label
    }()

    lazy var actionButton: Button = {
        let button = Button(theme: theme)
        button.style = .secondary
        button.setTitle("Probeer opnieuw", for: .normal)
        return button
    }()

    override func build() {
        super.build()
        addSubview(stackView)
        addSubview(actionButton)
    }

    override func setupConstraints() {
        super.setupConstraints()

        stackView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(34)
            maker.centerY.equalToSuperview()
        }

        imageView.snp.makeConstraints { maker in
            maker.width.equalTo(self).multipliedBy(0.6)
        }

        titleLabel.snp.makeConstraints { maker in
            maker.width.equalTo(stackView)
        }

        subtitleLabel.snp.makeConstraints { maker in
            maker.width.equalTo(stackView)
        }

        actionButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(safeAreaLayoutGuide).inset(16)
            maker.height.equalTo(50)

            constrainToSafeLayoutGuidesWithBottomMargin(maker: maker)
        }
    }
}
