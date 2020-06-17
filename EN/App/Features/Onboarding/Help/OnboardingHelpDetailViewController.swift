//
//  OnboardingHelpDetailViewController.swift
//  EN
//
//  Created by Rob Mulder on 17/06/2020.
//

import UIKit
import WebKit

/// @mockable
protocol OnboardingHelpDetailViewControllable: ViewControllable {
    func acceptButtonPressed()
}

final class OnboardingHelpDetailViewController: ViewController, OnboardingHelpDetailViewControllable {

    init(listener: OnboardingHelpListener,
        onboardingConsentHelp: OnboardingConsentHelp,
        theme: Theme) {
        self.onboardingConsentHelp = onboardingConsentHelp
        self.listener = listener

        super.init(theme: theme)
    }

    // MARK: - ViewController Lifecycle

    override func loadView() {
        self.view = internalView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        internalView.titleLabel.attributedText = onboardingConsentHelp?.attributedTitle
        internalView.contentTextView.attributedText = onboardingConsentHelp?.attributedAnswer
        internalView.closeButton.addTarget(self, action: #selector(closeButtonPressed), for: .touchUpInside)
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
    private weak var onboardingConsentHelp: OnboardingConsentHelp?
    private lazy var internalView: OnboardingHelpView = OnboardingHelpView(theme: self.theme)
}

private final class OnboardingHelpView: View {

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

    lazy var closeButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "CloseButton"), for: .normal)
        return button
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

    private lazy var viewsInDisplayOrder = [closeButton, titleLabel, contentTextView, gradientImageView, acceptButton]

    override func build() {
        super.build()

        viewsInDisplayOrder.forEach { addSubview($0) }
    }

    override func setupConstraints() {
        super.setupConstraints()

        var constraints = [[NSLayoutConstraint]()]

        constraints.append([
            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            closeButton.heightAnchor.constraint(equalToConstant: 50),
            closeButton.widthAnchor.constraint(equalTo: closeButton.heightAnchor)
            ])

        constraints.append([
            titleLabel.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 0),
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
