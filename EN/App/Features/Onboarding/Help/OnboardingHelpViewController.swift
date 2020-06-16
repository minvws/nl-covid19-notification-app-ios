/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import WebKit

/// @mockable
protocol OnboardingHelpViewControllable: ViewControllable {
    func acceptButtonPressed()
}

final class OnboardingHelpViewController: ViewController, OnboardingHelpViewControllable {

    init(listener: OnboardingHelpListener,
         theme: Theme) {
        self.listener = listener

        super.init(theme: theme)
    }

    // MARK: - ViewController Lifecycle

    override func loadView() {
        self.view = internalView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        internalView.titleLabel.text = Localized("helpTitle")
        internalView.closeButton.addTarget(self, action: #selector(closeButtonPressed), for: .touchUpInside)

        if let url = Bundle.main.url(forResource: "template", withExtension: "html") {
            if let template = try? String(contentsOf: url) {
                let html = template.replacingOccurrences(of: "%s", with: Localized("helpContent") + "</br>")
                internalView.webView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
            }
        }
    }

    @objc func closeButtonPressed() {
        self.dismiss(animated: true)
    }

    @objc func acceptButtonPressed() {
        self.dismiss(animated: true, completion: {
            // TODO: Ask permissions
        })
    }

    // MARK: - Private

    private weak var listener: OnboardingHelpListener?
    private lazy var internalView: OnboardingHelpView = OnboardingHelpView(theme: self.theme)
}

private final class OnboardingHelpView: View {

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textAlignment = .center
        return label
    }()

    private lazy var lineView: UIView = {
        let lineView = UILabel()
        lineView.translatesAutoresizingMaskIntoConstraints = false
        lineView.backgroundColor = .black
        return lineView
    }()

    lazy var closeButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "CloseButton"), for: .normal)
        return button
    }()

    lazy var webView: WKWebView = {
        let webView = WKWebView()
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.allowsBackForwardNavigationGestures = false
        webView.backgroundColor = .clear
        return webView
    }()

    private lazy var gradientImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .clear
        imageView.image = UIImage(named: "Gradient") ?? UIImage()
        return imageView
    }()

    lazy var acceptButton: Button = {
        let button = Button(theme: self.theme)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.style = .primary
        button.title = Localized("helpAcceptButtonTitle")
        return button
    }()

    private lazy var viewsInDisplayOrder = [titleLabel, closeButton, lineView, webView, gradientImageView, acceptButton]

    override func build() {
        super.build()

        viewsInDisplayOrder.forEach { addSubview($0) }
    }

    override func setupConstraints() {
        super.setupConstraints()

        var constraints = [[NSLayoutConstraint]()]

        constraints.append([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 75)
        ])

        constraints.append([
            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            closeButton.heightAnchor.constraint(equalToConstant: 75),
            closeButton.widthAnchor.constraint(equalTo: closeButton.heightAnchor)
        ])

        constraints.append([
            lineView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            lineView.leadingAnchor.constraint(equalTo: leadingAnchor),
            lineView.trailingAnchor.constraint(equalTo: trailingAnchor),
            lineView.heightAnchor.constraint(equalToConstant: 1)
        ])

        constraints.append([
            webView.topAnchor.constraint(equalTo: lineView.bottomAnchor, constant: 0),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            webView.bottomAnchor.constraint(equalTo: acceptButton.topAnchor, constant: 0)
        ])

        constraints.append([
            gradientImageView.heightAnchor.constraint(equalToConstant: 25),
            gradientImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            gradientImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            gradientImageView.bottomAnchor.constraint(equalTo: acceptButton.topAnchor, constant: 0)
        ])

        constraints.append([
            acceptButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -50),
            acceptButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            acceptButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            acceptButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        for constraint in constraints { NSLayoutConstraint.activate(constraint) }
    }
}
