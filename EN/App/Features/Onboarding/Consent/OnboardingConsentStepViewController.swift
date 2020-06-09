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

    private var index: Int
    private let onboardingConsentManager: OnboardingConsentManaging
    private let onboardingConsentStepBuilder: OnboardingConsentBuildable

    init(onboardingConsentManager: OnboardingConsentManaging,
        onboardingConcentStepBuilder: OnboardingConsentBuildable,
        listener: OnboardingConsentListener,
        index: Int) {

        self.onboardingConsentManager = onboardingConsentManager
        self.onboardingConsentStepBuilder = onboardingConcentStepBuilder
        self.listener = listener
        self.index = index
        
        guard let step = self.onboardingConsentManager.getStep(index) else { fatalError("ConsentStep index out of range") }
        
        self.internalView = OnboardingConsentView(step: step)

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
        
        self.skipStepButton.target = self

        setThemeNavigationBar()
        setNavigationRightBarButtonItems([skipStepButton])
    }

    @objc func skipStepButtonPressed() {

    }

    // MARK: - Private

    private weak var listener: OnboardingConsentListener?
    private var internalView: OnboardingConsentView
}

private final class OnboardingConsentView: View {

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

    lazy private var primaryButton: Button = {
        let button = Button()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.style = .primary
        button.addTarget(self, action: #selector(primaryButtonPressed), for: .touchUpInside)
        return button
    }()

    lazy private var secondaryButton: Button = {
        let button = Button()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.style = .tertiary
        button.addTarget(self, action: #selector(secondaryButtonPressed), for: .touchUpInside)
        return button
    }()

    lazy private var viewsInDisplayOrder = [imageView, primaryButton, secondaryButton, label]

    private var consentSummaryStepsView: OnboardingConsentSummaryStepsView?

    private var consentStep: OnboardingConsentStep

    init(step: OnboardingConsentStep) {
        self.consentStep = step
        super.init(frame: .zero)

        build()
        setupConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func build() {
        super.build()
        
        backgroundColor = .red
        
        self.primaryButton.title = self.consentStep.primaryButtonTitle
        self.secondaryButton.title = self.consentStep.secondaryButtonTitle

        if let image = self.consentStep.image {
            self.imageView.image = image
            self.imageView.isHidden = false
        }

        if self.consentStep.hasSummarySteps {
            consentSummaryStepsView = OnboardingConsentSummaryStepsView(with: self.consentStep.summarySteps!)
            viewsInDisplayOrder.append(consentSummaryStepsView!)
        }

        self.label.attributedText = self.consentStep.attributedText
        
        for subView in viewsInDisplayOrder { addSubview(subView) }
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
            label.topAnchor.constraint(equalTo: self.consentStep.hasImage ? imageView.bottomAnchor : topAnchor, constant: 25),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            label.heightAnchor.constraint(greaterThanOrEqualToConstant: 0)
            ])

        if self.consentStep.hasSummarySteps {
            constraints.append([
                consentSummaryStepsView!.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20),
                consentSummaryStepsView!.leadingAnchor.constraint(equalTo: leadingAnchor, constant: OnboardingConsentStepViewController.onboardingConsentSummaryStepsViewLeadingMargin),
                consentSummaryStepsView!.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -OnboardingConsentStepViewController.onboardingConsentSummaryStepsViewTrailingMargin),
                consentSummaryStepsView!.bottomAnchor.constraint(equalTo: secondaryButton.topAnchor, constant: -20)
                ])
        }

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

        for constraint in constraints { NSLayoutConstraint.activate(constraint) } }

    //MARK: - Functions

    @objc func primaryButtonPressed() {

    }

    @objc func secondaryButtonPressed() {

    }
}

