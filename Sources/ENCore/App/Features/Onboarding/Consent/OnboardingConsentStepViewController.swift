/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Lottie
import UIKit

/// @mockable
protocol OnboardingConsentViewControllable: ViewControllable {}

final class OnboardingConsentStepViewController: ViewController, OnboardingConsentViewControllable {

    private lazy var skipStepButton: UIBarButtonItem = {
        let button = UIBarButtonItem()
        button.target = self
        button.title = Localization.string(for: "skipStep")
        button.tintColor = self.theme.colors.primary
        button.action = #selector(skipStepButtonPressed)
        return button
    }()

    static let onboardingConsentSummaryStepsViewLeadingMargin: CGFloat = 16
    static let onboardingConsentSummaryStepsViewTrailingMargin: CGFloat = 16

    private let onboardingConsentManager: OnboardingConsentManaging

    private let consentStep: OnboardingConsentStep?

    init(onboardingConsentManager: OnboardingConsentManaging,
         listener: OnboardingConsentListener,
         theme: Theme,
         index: Int) {

        self.onboardingConsentManager = onboardingConsentManager
        self.listener = listener
        self.consentStep = self.onboardingConsentManager.getStep(index)

        super.init(theme: theme)
    }

    // MARK: - ViewController Lifecycle

    override func loadView() {
        self.view = internalView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        hasBottomMargin = true

        internalView.consentStep = consentStep
        internalView.primaryButton.addTarget(self, action: #selector(primaryButtonPressed), for: .touchUpInside)
        internalView.secondaryButton.addTarget(self, action: #selector(secondaryButtonPressed), for: .touchUpInside)

        self.skipStepButton.target = self

        setThemeNavigationBar()

        if consentStep?.hasNavigationBarSkipButton ?? false {
            setNavigationRightBarButtonItems([skipStepButton])
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.internalView.animationView.play()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.internalView.animationView.stop()
    }

    // MARK: - Functions

    @objc private func primaryButtonPressed() {
        if let consentStep = consentStep {
            switch consentStep.step {
            case .en:
                onboardingConsentManager.askEnableExposureNotifications { activeState in
                    switch activeState {
                    case .notAuthorized:
                        self.closeConsent()
                    default:
                        self.goToNextStepOrCloseConsent()
                    }
                }
            case .bluetooth:
                onboardingConsentManager.goToBluetoothSettings {
                    self.goToNextStepOrCloseConsent()
                }
            case .notifications:
                onboardingConsentManager.askNotificationsAuthorization {
                    self.goToNextStepOrCloseConsent()
                }
            }
        }
    }

    @objc private func secondaryButtonPressed() {
        if let consentStep = consentStep {
            switch consentStep.step {
            case .en:
                self.listener?.displayHelp()
            case .bluetooth, .notifications:
                self.goToNextStepOrCloseConsent()
            }
        }
    }

    private func closeConsent() {
        self.listener?.consentClose()
    }

    private func goToNextStepOrCloseConsent() {
        if let consentStep = consentStep {
            onboardingConsentManager.getNextConsentStep(consentStep.step) { nextStep in
                if let nextStep = nextStep {
                    self.listener?.consentRequest(step: nextStep)
                } else {
                    self.listener?.consentClose()
                }
            }
        }
    }

    @objc func skipStepButtonPressed() {
        goToNextStepOrCloseConsent()
    }

    // MARK: - Private

    private weak var listener: OnboardingConsentListener?
    private lazy var internalView: OnboardingConsentView = OnboardingConsentView(theme: self.theme)
}

final class OnboardingConsentView: View {

    private lazy var scrollView = UIScrollView()

    lazy var animationView: AnimationView = {
        let animationView = AnimationView()
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.isHidden = true
        animationView.loopMode = .loop
        return animationView
    }()

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        imageView.isHidden = true
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

    lazy var primaryButton: Button = {
        let button = Button(theme: self.theme)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.style = .primary
        return button
    }()

    lazy var secondaryButton: Button = {
        let button = Button(theme: self.theme)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.style = .secondary
        return button
    }()

    private lazy var viewsInDisplayOrder = [imageView, animationView, titleLabel, contentLabel]

    private var consentSummaryStepsView: OnboardingConsentSummaryStepsView?

    var consentStep: OnboardingConsentStep? {
        didSet {
            updateView()
            updateViewConstraints()
        }
    }

    override func build() {
        super.build()

        addSubview(scrollView)
        scrollView.alwaysBounceVertical = true

        addSubview(primaryButton)
        addSubview(secondaryButton)

        viewsInDisplayOrder.forEach { scrollView.addSubview($0) }
    }

    override func setupConstraints() {
        super.setupConstraints()

        hasBottomMargin = true

        scrollView.snp.makeConstraints { maker in
            maker.top.leading.trailing.equalTo(safeAreaLayoutGuide)
            maker.width.equalToSuperview()
            maker.bottom.equalTo(secondaryButton.snp.top).inset(-16)
        }

        animationView.snp.makeConstraints { maker in
            maker.top.leading.trailing.equalTo(self)
        }

        primaryButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(16)
            maker.height.equalTo(50)

            constrainToSafeLayoutGuidesWithBottomMargin(maker: maker)
        }

        secondaryButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(16)
            maker.height.equalTo(50)

            maker.bottom.equalTo(primaryButton.snp.top).inset(-16)
        }
    }

    private func updateView() {

        guard let step = self.consentStep else {
            return
        }

        self.titleLabel.attributedText = step.attributedTitle
        self.contentLabel.attributedText = step.attributedContent

        self.primaryButton.title = step.primaryButtonTitle
        self.secondaryButton.title = step.secondaryButtonTitle

        if let animation = step.animation {
            self.animationView.animation = animation
            self.animationView.isHidden = false
        } else if let image = step.image {
            self.imageView.image = image
            self.imageView.isHidden = false
        }

        if let width = imageView.image?.size.width,
            let height = imageView.image?.size.height,
            width > 0, height > 0 {

            let aspectRatio = height / width

            imageView.snp.makeConstraints { maker in
                maker.top.equalToSuperview()
                maker.leading.trailing.equalToSuperview()
                maker.width.lessThanOrEqualTo(scrollView).inset(16)
                maker.height.equalTo(scrollView.snp.width).multipliedBy(aspectRatio)
            }
        }

        imageView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.width.equalTo(self)
        }

        guard let summarySteps = step.summarySteps else {
            return
        }

        if step.hasSummarySteps {

            consentSummaryStepsView = OnboardingConsentSummaryStepsView(with: summarySteps, theme: theme)

            subviews.forEach {
                if $0 is OnboardingConsentSummaryStepView {
                    $0.removeFromSuperview()
                }
            }

            if let consentSummaryStepsView = consentSummaryStepsView {
                scrollView.addSubview(consentSummaryStepsView)
            }
        }
    }

    private func updateViewConstraints() {

        guard let step = self.consentStep else { return }

        titleLabel.snp.remakeConstraints { maker in
            maker.leading.trailing.equalTo(self).inset(16)
            maker.height.greaterThanOrEqualTo(50)
            maker.top.equalTo(step.hasImage ? imageView.snp.bottom : scrollView.snp.top).offset(25)
        }

        contentLabel.snp.remakeConstraints { maker in
            maker.top.equalTo(titleLabel.snp.bottom).offset(16)
            maker.leading.trailing.equalTo(self).inset(16)
            maker.height.greaterThanOrEqualTo(50)
            maker.bottom.lessThanOrEqualTo(scrollView.snp.bottom)
        }

        if let consentSummaryStepsView = consentSummaryStepsView {

            if step.hasSummarySteps {

                consentSummaryStepsView.snp.remakeConstraints { maker in
                    maker.top.equalTo(titleLabel.snp.bottom).offset(20)
                    maker.leading.trailing.equalTo(self).inset(16)
                    maker.bottom.lessThanOrEqualTo(scrollView.snp.bottom)
                }
            }
        }
    }
}
