/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol OnboardingStepViewControllable: ViewControllable {}

final class OnboardingStepViewController: ViewController, OnboardingStepViewControllable {

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()

    private lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()

    private lazy var button: Button = {
        let button = Button(theme: self.theme)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        return button
    }()

    private lazy var viewsInDisplayOrder = [imageView, button, titleLabel, contentLabel]

    private var index: Int
    private var onboardingStep: OnboardingStep
    private let onboardingManager: OnboardingManaging
    private let onboardingStepBuilder: OnboardingStepBuildable

    private weak var listener: OnboardingStepListener?

    // MARK: - Lifecycle

    init(onboardingManager: OnboardingManaging,
         onboardingStepBuilder: OnboardingStepBuildable,
         listener: OnboardingStepListener,
         theme: Theme,
         index: Int) {

        self.onboardingManager = onboardingManager
        self.onboardingStepBuilder = onboardingStepBuilder
        self.listener = listener
        self.index = index

        guard let step = self.onboardingManager.getStep(index) else { fatalError("OnboardingStep index out of range") }

        self.onboardingStep = step

        super.init(theme: theme)

        self.button.title = self.onboardingStep.buttonTitle
        self.imageView.image = self.onboardingStep.image
        self.titleLabel.attributedText = self.onboardingStep.attributedTitle
        self.contentLabel.attributedText = self.onboardingStep.attributedContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        setupConstraints()
    }

    // MARK: - Setups

    private func setupViews() {
        setThemeNavigationBar()

        viewsInDisplayOrder.forEach { view.addSubview($0) }
    }

    private func setupConstraints() {

        var constraints = [[NSLayoutConstraint]()]

        constraints.append([
            imageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 0.83, constant: 1)
        ])

        constraints.append([
            button.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            button.heightAnchor.constraint(equalToConstant: 50)
        ])

        constraints.append([
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 0),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 50)
        ])

        constraints.append([
            contentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            contentLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            contentLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            contentLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 50)
        ])

        for constraint in constraints { NSLayoutConstraint.activate(constraint) }

        self.contentLabel.sizeToFit()
    }

    // MARK: - Functions

    @objc func buttonPressed() {
        let nextIndex = self.index + 1
        if onboardingManager.onboardingSteps.count > nextIndex {
            let viewController = onboardingStepBuilder.build(withListener: listener!, initialIndex: nextIndex)
            self.navigationController?.pushViewController(viewController.uiviewController, animated: true)
        } else {
            // build consent
            listener?.onboardingStepsDidComplete()
        }
    }
}
