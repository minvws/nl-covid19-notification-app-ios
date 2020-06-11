/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import UIKit

/// @mockable
protocol OnboardingConsentViewControllable: ViewControllable { }

final class OnboardingConsentStepViewController: ViewController, OnboardingConsentViewControllable {

    lazy private var skipStepButton: UIBarButtonItem = {
        let button = UIBarButtonItem()
        button.target = self
        button.title = Localized("skipStep")
        button.tintColor = .primaryColor
        button.action = #selector(skipStepButtonPressed)
        return button
    }()

    static let onboardingConsentSummaryStepsViewLeadingMargin: CGFloat = 20
    static let onboardingConsentSummaryStepsViewTrailingMargin: CGFloat = 20

    private let onboardingConsentManager: OnboardingConsentManaging

    private let consentStep: OnboardingConsentStep?

    init(onboardingConsentManager: OnboardingConsentManaging,
        listener: OnboardingConsentListener,
        index: Int) {

        self.onboardingConsentManager = onboardingConsentManager
        self.listener = listener
        self.consentStep = self.onboardingConsentManager.getStep(index)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - ViewController Lifecycle

    override func loadView() {
        self.view = internalView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .viewControllerBackgroundColor

        internalView.consentStep = consentStep
        internalView.primaryButton.addTarget(self, action: #selector(primaryButtonPressed), for: .touchUpInside)
        internalView.secondaryButton.addTarget(self, action: #selector(secondaryButtonPressed), for: .touchUpInside)

        self.skipStepButton.target = self

        setThemeNavigationBar()

        if consentStep?.hasNavigationBarSkipButton ?? false {
            setNavigationRightBarButtonItems([skipStepButton])
        }
    }

    //MARK: - Functions

    @objc private func primaryButtonPressed() {
        if let consentStep = consentStep {
            switch consentStep.step {
            case .en:
                onboardingConsentManager.askEnableExposureNotifications {
                    self.goToNextStepOrCloseConsent()
                }
            case .bluetooth:
                onboardingConsentManager.askEnableBluetooth {
                    self.goToNextStepOrCloseConsent()
                }
            }
        }
    }

    @objc private func secondaryButtonPressed() {
        if let consentStep = consentStep {
            switch consentStep.step {
            case .en, .bluetooth:
                self.goToNextStepOrCloseConsent()
            }
        }
    }

    private func goToNextStepOrCloseConsent() {
        if let consentStep = consentStep {
            if let nextStep = onboardingConsentManager.getNextConsentStep(consentStep.step) {
                self.listener?.consentRequest(step: nextStep)
            } else {
                self.listener?.consentClose()
            }
        }
    }

    @objc func skipStepButtonPressed() {

        if let consentStep = consentStep {
            if let nextStep = onboardingConsentManager.getNextConsentStep(consentStep.step) {
                self.listener?.consentRequest(step: nextStep)
            } else {
                self.listener?.consentClose()
            }
        }
    }

    // MARK: - Private

    private weak var listener: OnboardingConsentListener?
    private lazy var internalView: OnboardingConsentView = OnboardingConsentView()
}

final class OnboardingConsentView: View {

    lazy private var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        imageView.isHidden = true
        return imageView
    }()

    lazy private var label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()

    lazy var primaryButton: Button = {
        let button = Button()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.style = .primary
        return button
    }()

    lazy var secondaryButton: Button = {
        let button = Button()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.style = .tertiary
        return button
    }()

    lazy private var viewsInDisplayOrder = [imageView, primaryButton, secondaryButton, label]

    private var consentSummaryStepsView: OnboardingConsentSummaryStepsView?

    var consentStep: OnboardingConsentStep? {
        didSet {
            updateView()
            updateViewConstraints()
        }
    }

    override func build() {
        super.build()

        viewsInDisplayOrder.forEach { addSubview($0) }
    }

    override func setupConstraints() {
        super.setupConstraints()

        var constraints = [[NSLayoutConstraint]()]

        constraints.append([
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 0.83, constant: 1)
            ])

        constraints.append([
            primaryButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -50),
            primaryButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            primaryButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            primaryButton.heightAnchor.constraint(equalToConstant: 50),
            ])

        constraints.append([
            secondaryButton.bottomAnchor.constraint(equalTo: primaryButton.topAnchor, constant: -20),
            secondaryButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            secondaryButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            secondaryButton.heightAnchor.constraint(equalToConstant: 50),
            ])

        for constraint in constraints { NSLayoutConstraint.activate(constraint) }
    }

    private func updateView() {

        guard let step = self.consentStep else {
            return
        }

        self.label.attributedText = step.attributedText

        self.primaryButton.title = step.primaryButtonTitle
        self.secondaryButton.title = step.secondaryButtonTitle

        if let image = step.image {
            self.imageView.image = image
            self.imageView.isHidden = false
        }

        guard let summarySteps = step.summarySteps else {
            return
        }

        if step.hasSummarySteps {

            consentSummaryStepsView = OnboardingConsentSummaryStepsView(with: summarySteps)

            subviews.forEach({
                if $0 is OnboardingConsentSummaryStepView {
                    $0.removeFromSuperview()
                }
            })

            if let consentSummaryStepsView = consentSummaryStepsView {
                addSubview(consentSummaryStepsView)
            }
        }
    }

    private func updateViewConstraints() {

        guard let step = self.consentStep else { return }

        var constraints = [[NSLayoutConstraint]()]

        label.constraints.forEach({ label.removeConstraint($0) })

        constraints.append([
            label.topAnchor.constraint(equalTo: step.hasImage ? imageView.bottomAnchor : topAnchor, constant: 25),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            label.heightAnchor.constraint(greaterThanOrEqualToConstant: 0)
            ])

        if let consentSummaryStepsView = consentSummaryStepsView {

            consentSummaryStepsView.constraints.forEach({ consentSummaryStepsView.removeConstraint($0) })

            if step.hasSummarySteps {

                constraints.append([
                    consentSummaryStepsView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20),
                    consentSummaryStepsView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: OnboardingConsentStepViewController.onboardingConsentSummaryStepsViewLeadingMargin),
                    consentSummaryStepsView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -OnboardingConsentStepViewController.onboardingConsentSummaryStepsViewTrailingMargin),
                    consentSummaryStepsView.bottomAnchor.constraint(equalTo: secondaryButton.topAnchor, constant: -20)
                    ])

                consentSummaryStepsView.setupConstraints()
            }
        }

        for constraint in constraints { NSLayoutConstraint.activate(constraint) }
    }
}

