/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import UIKit

class OnboardingStepViewController: UIViewController {

    lazy private var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        return imageView
    }()

    lazy private var label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()

    lazy private var button: Button = {
        let button = Button()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        return button
    }()

    lazy private var viewsInDisplayOrder = [imageView, button, label]

    var index: Int
    var onboardingStep: OnboardingStep

    // MARK: - Lifecycle

    init(index: Int) {

        self.index = index

        guard let step = OnboardingManager.shared.getStep(index) else {
            fatalError("OnboardingStep index out of range")
        }

        self.onboardingStep = step

        super.init(nibName: nil, bundle: nil)

        self.button.title = self.onboardingStep.buttonTitle
        self.imageView.image = self.onboardingStep.image
        self.label.attributedText = self.onboardingStep.attributedText

        self.button.isHidden = OnboardingManager.shared.onboardingSteps.count == self.index + 1
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        setupConstraints()
    }

    // MARK: - Setups

    private func setupViews() {

        view.backgroundColor = .viewControllerBackgroundColor

        setThemeNavigationBar()

        for subView in viewsInDisplayOrder { view.addSubview(subView) }
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
            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 0),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            label.bottomAnchor.constraint(equalTo: button.topAnchor, constant: 0)
            ])

        for constraint in constraints { NSLayoutConstraint.activate(constraint) }
    }

    // MARK: - Functions

    @objc func buttonPressed() {
        let nextIndex = self.index + 1
        if OnboardingManager.shared.onboardingSteps.count > nextIndex {
            self.navigationController?.pushViewController(
                OnboardingStepViewController(index: nextIndex),
                animated: true
            )
        }
    }
}
