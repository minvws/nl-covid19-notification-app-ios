/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import UIKit
import WebKit

final class HelpDetailViewController: ViewController, Logging {

    init(listener: HelpDetailListener,
         shouldShowEnableAppButton: Bool,
         question: HelpQuestion,
         theme: Theme) {
        self.listener = listener
        self.shouldShowEnableAppButton = shouldShowEnableAppButton
        self.question = question

        super.init(theme: theme)
    }

    // MARK: - ViewController Lifecycle

    override func loadView() {
        self.view = internalView
        self.view.frame = UIScreen.main.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        internalView.titleLabel.attributedText = question.attributedTitle

        internalView.contentTextView.attributedText = question.attributedAnswer

        internalView.acceptButton.addTarget(self, action: #selector(acceptButtonPressed), for: .touchUpInside)

        navigationItem.rightBarButtonItem = navigationController?.navigationItem.rightBarButtonItem
    }

    @objc func acceptButtonPressed() {
        listener?.helpDetailDidTapEnableAppButton()
    }

    // MARK: - Private

    private lazy var internalView: HelpView = HelpView(theme: theme, shouldDisplayButton: shouldShowEnableAppButton)
    private weak var listener: HelpDetailListener?

    private let shouldShowEnableAppButton: Bool
    private let question: HelpQuestion
}

private final class HelpView: View {

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.accessibilityTraits = .header
        return label
    }()

    lazy var contentTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        return textView
    }()

    private lazy var gradientImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .clear
        imageView.image = .gradient ?? UIImage()
        return imageView
    }()

    lazy var acceptButton: Button = {
        let button = Button(theme: self.theme)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.style = .primary
        button.title = .helpAcceptButtonTitle
        return button
    }()

    init(theme: Theme, shouldDisplayButton: Bool) {
        self.shouldDisplayButton = shouldDisplayButton
        super.init(theme: theme)
    }

    override func build() {
        super.build()

        addSubview(titleLabel)
        addSubview(contentTextView)

        addSubview(gradientImageView)

        if shouldDisplayButton {
            addSubview(acceptButton)
        }
    }

    override func setupConstraints() {
        super.setupConstraints()

        var constraints = [[NSLayoutConstraint]()]

        let bottomAnchor = shouldDisplayButton ? acceptButton.topAnchor : self.bottomAnchor

        constraints.append([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 25)
        ])

        constraints.append([
            contentTextView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 15),
            contentTextView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            contentTextView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15),
            contentTextView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0)
        ])

        constraints.append([
            gradientImageView.heightAnchor.constraint(equalToConstant: 25),
            gradientImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            gradientImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            gradientImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0)
        ])

        if shouldDisplayButton {
            constraints.append([
                acceptButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -20),
                acceptButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
                acceptButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
                acceptButton.heightAnchor.constraint(equalToConstant: 50)
            ])
        }

        for constraint in constraints { NSLayoutConstraint.activate(constraint) }
    }

    // MARK: - Private

    private let shouldDisplayButton: Bool
}
