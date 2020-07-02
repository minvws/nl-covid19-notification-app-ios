/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import SnapKit
import UIKit

/// @mockable
protocol UpdateAppViewControllable: ViewControllable {}

final class UpdateAppViewController: ViewController, UpdateAppViewControllable, UIAdaptivePresentationControllerDelegate, Logging {

    // MARK: - Init

    init(listener: UpdateAppListener,
         theme: Theme,
         appStoreURL: String?,
         minimumVersionMessage: String?) {

        self.listener = listener
        self.appStoreURL = appStoreURL
        self.minimumVersionMessage = minimumVersionMessage

        super.init(theme: theme)

        modalPresentationStyle = .fullScreen
    }

    // MARK: - ViewController Lifecycle

    override func loadView() {

        self.view = internalView
        self.view.frame = UIScreen.main.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        internalView.imageView.image = Image.named("UpdateApp")
        internalView.titleLabel.attributedText = .makeFromHtml(
            text: Localization.string(for: "updateApp.title"),
            font: theme.fonts.title2,
            textColor: .black)
        internalView.contentLabel.attributedText = .makeFromHtml(
            text: minimumVersionMessage ?? Localization.string(for: "updateApp.content"),
            font: theme.fonts.body,
            textColor: theme.colors.gray)
        internalView.button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
    }

    // MARK: - Functions

    @objc func buttonPressed() {
        guard let storeUrl = URL(string: appStoreURL ?? ""),
            UIApplication.shared.canOpenURL(storeUrl) else {
            showCannotOpenSettingsAlert()
            logError("Can't open: \(appStoreURL ?? "")")
            return
        }
        UIApplication.shared.open(storeUrl)
    }

    private func showCannotOpenSettingsAlert() {
        let alertController = UIAlertController(title: Localization.string(for: "error.title"),
                                                message: Localization.string(for: "updateApp.error.message"),
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: Localization.string(for: "ok"), style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

    // MARK: - Private

    private weak var listener: UpdateAppListener?
    private lazy var internalView: UpdateAppView = {
        UpdateAppView(theme: self.theme)
    }()
    private var appStoreURL: String?
    private var minimumVersionMessage: String?
}

private final class UpdateAppView: View {

    lazy var button: Button = {
        let button = Button(theme: self.theme)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.title = Localization.string(for: "updateApp.button")
        return button
    }()

    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        return imageView
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()

    lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()

    private lazy var viewsInDisplayOrder = [button, imageView, titleLabel, contentLabel]

    // MARK: - Init

    override init(theme: Theme) {

        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        viewsInDisplayOrder.forEach { addSubview($0) }
    }

    override func setupConstraints() {
        super.setupConstraints()

        var constraints = [[NSLayoutConstraint]()]

        constraints.append([
            button.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -50),
            button.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            button.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            button.heightAnchor.constraint(equalToConstant: 50)
        ])

        constraints.append([
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 75),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 0.83, constant: 1)
        ])

        constraints.append([
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 50),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 50)
        ])

        constraints.append([
            contentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            contentLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            contentLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            contentLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 50)
        ])

        for constraint in constraints { NSLayoutConstraint.activate(constraint) }

        self.contentLabel.sizeToFit()
    }
}
