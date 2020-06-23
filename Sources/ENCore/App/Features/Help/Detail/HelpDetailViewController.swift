/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import WebKit

final class HelpDetailViewController: ViewController {

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
        internalView.acceptButton.isHidden = !shouldShowEnableAppButton
    }

    @objc func acceptButtonPressed() {
        listener?.helpDetailDidTapEnableAppButton()
    }

    @objc func closeButtonPressed() {
        listener?.helpDetailRequestsDismissal(shouldDismissViewController: true)
    }

    // MARK: - Private

    private weak var listener: HelpDetailListener?
    private let shouldShowEnableAppButton: Bool
    private let question: HelpQuestion
    private lazy var internalView: HelpView = HelpView(theme: self.theme)
}

private final class HelpView: View {

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
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
        imageView.image = Image.named("Gradient") ?? UIImage()
        return imageView
    }()

    lazy var acceptButton: Button = {
        let button = Button(theme: self.theme)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.style = .primary
        button.title = Localized("helpAcceptButtonTitle")
        return button
    }()

    private lazy var viewsInDisplayOrder = [titleLabel, contentTextView, gradientImageView, acceptButton]

    override func build() {
        super.build()

        viewsInDisplayOrder.forEach { addSubview($0) }
    }

    override func setupConstraints() {
        super.setupConstraints()

        var constraints = [[NSLayoutConstraint]()]

        constraints.append([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 15),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 25)
            ])

        constraints.append([
            contentTextView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 15),
            contentTextView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            contentTextView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            contentTextView.bottomAnchor.constraint(equalTo: acceptButton.topAnchor, constant: 0)
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
