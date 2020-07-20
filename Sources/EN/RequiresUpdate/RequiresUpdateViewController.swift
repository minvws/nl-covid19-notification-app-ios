/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import UIKit

final class RequiresUpdateViewController: UIViewController {

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        setupConstraints()
    }

    // MARK: - Setups

    private func setupViews() {

        self.view = internalView
        self.view.frame = UIScreen.main.bounds
        self.view.backgroundColor = .white

        self.view.addSubview(button)

        internalView.titleLabel.text = localizedString(for: "update.hardware.title")
        internalView.titleLabel.font = font(size: 22, weight: .bold, textStyle: .title2)

        internalView.contentLabel.text = localizedString(for: "update.hardware.description")
        internalView.contentLabel.font = font(size: 17, weight: .regular, textStyle: .body)
    }

    private func setupConstraints() {

        var constraints = [[NSLayoutConstraint]()]

        constraints.append([
            button.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            button.heightAnchor.constraint(equalToConstant: 50)
        ])

        for constraint in constraints { NSLayoutConstraint.activate(constraint) }
    }

    // MARK: - Functions

    @objc func buttonPressed() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
            UIApplication.shared.canOpenURL(settingsUrl) else {
            showCannotOpenSettingsAlert()
            return
        }
        UIApplication.shared.open(settingsUrl)
    }

    private func showCannotOpenSettingsAlert() {
        let alertController = UIAlertController(title: localizedString(for: "alertTitle"),
                                                message: localizedString(for: "alertMessage"),
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: localizedString(for: "alertButton"), style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

    /// Get the scaled font
    private func font(size: CGFloat, weight: UIFont.Weight, textStyle: UIFont.TextStyle) -> UIFont {
        let font = UIFont.systemFont(ofSize: size, weight: weight)
        let fontMetrics = UIFontMetrics(forTextStyle: textStyle)
        return fontMetrics.scaledFont(for: font)
    }

    /// Get the Localized string for the current bundle.
    private func localizedString(for key: String, comment: String = "", _ arguments: [CVarArg] = []) -> String {
        let value = NSLocalizedString(key, comment: comment)
        guard value == key else {
            return String(format: value, arguments: arguments)
        }
        guard
            let path = Bundle.main.path(forResource: "Base", ofType: "lproj"),
            let bundle = Bundle(path: path) else {
            return String(format: value, arguments: arguments)
        }
        let localizedString = NSLocalizedString(key, bundle: bundle, comment: "")
        return String(format: localizedString, arguments: arguments)
    }

    // MARK: - Private

    private lazy var internalView: RequiresUpdateView = RequiresUpdateView()

    private lazy var button: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(localizedString(for: "update.button.update"), for: .normal)
        button.titleLabel?.font = font(size: 17, weight: .bold, textStyle: .body)
        button.layer.cornerRadius = 10
        button.clipsToBounds = true
        button.backgroundColor = UIColor(named: "PrimaryColor")
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        return button
    }()
}

final class RequiresUpdateView: UIView {

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        imageView.image = UIImage(named: "SoftwareUpdate")
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

    private lazy var viewsInDisplayOrder = [imageView, titleLabel, contentLabel]

    // MARK: - Live cycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupViews()
        setupConstraints()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setupViews()
        setupConstraints()
    }

    private func setupViews() {

        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .white
        viewsInDisplayOrder.forEach { addSubview($0) }
    }

    private func setupConstraints() {

        var constraints = [[NSLayoutConstraint]()]

        constraints.append([
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 75),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 0.83, constant: 1)
        ])

        constraints.append([
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
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

        constraints.forEach { NSLayoutConstraint.activate($0) }

        self.contentLabel.sizeToFit()
    }
}
