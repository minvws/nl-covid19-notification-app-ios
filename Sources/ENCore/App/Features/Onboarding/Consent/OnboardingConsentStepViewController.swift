/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Lottie
import UIKit

/// @mockable
protocol OnboardingConsentViewControllable: ViewControllable {}

final class OnboardingConsentStepViewController: ViewController, OnboardingConsentViewControllable {

    private lazy var skipStepButton: UIBarButtonItem = {
        let button = UIBarButtonItem()
        button.target = self
        button.title = .skipStep
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
                onboardingConsentManager.askNotificationsAuthorization {
                    self.onboardingConsentManager.askEnableExposureNotifications { activeState in
                        switch activeState {
                        case .notAuthorized:
                            self.closeConsent()
                        default:
                            self.goToNextStepOrCloseConsent()
                        }
                    }
                }
            case .bluetooth:
                self.listener?.displayBluetoothSettings()
            case .share:
                self.listener?.displayShareApp(completion: nil)
            }
        }
    }

    @objc private func secondaryButtonPressed() {
        if let consentStep = consentStep {
            switch consentStep.step {
            case .en:
                self.listener?.displayHelp()
            case .bluetooth, .share:
                self.goToNextStepOrCloseConsent()
            }
        }
    }

    private func closeConsent() {
        self.listener?.consentClose()
    }

    private func goToNextStepOrCloseConsent(skipCurrentStep: Bool = false) {
        if let consentStep = consentStep {
            onboardingConsentManager.getNextConsentStep(consentStep.step, skippedCurrentStep: skipCurrentStep) { nextStep in
                if let nextStep = nextStep {
                    self.listener?.consentRequest(step: nextStep)
                } else {
                    self.listener?.consentClose()
                }
            }
        }
    }

    @objc func skipStepButtonPressed() {
        if let consentStep = consentStep, consentStep.step == .en {
            onboardingConsentManager.isNotificationAuthorizationAsked { asked in
                if !asked {
                    let alertController = UIAlertController(title: .consentSkipEnTitle,
                                                            message: .consentSkipEnMessage,
                                                            preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: .consentSkipEnDeclineButton, style: .cancel, handler: { _ in
                        self.goToNextStepOrCloseConsent(skipCurrentStep: true)
                    }))
                    alertController.addAction(UIAlertAction(title: .consentSkipEnAcceptButton, style: .default, handler: { _ in
                        self.primaryButtonPressed()
                    }))
                    self.present(alertController, animated: true, completion: nil)
                } else {
                    self.goToNextStepOrCloseConsent(skipCurrentStep: true)
                }
            }
        } else {
            goToNextStepOrCloseConsent(skipCurrentStep: true)
        }
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
        button.isHidden = true
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
            maker.bottom.equalTo(primaryButton.snp.top).inset(-16)
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

        if let title = step.secondaryButtonTitle {
            self.secondaryButton.title = title
            self.secondaryButton.isHidden = false
        }

        if let animation = step.animation {
            self.animationView.animation = animation
            self.animationView.isHidden = false
        } else if let image = step.image {
            self.imageView.image = image
            self.imageView.isHidden = false
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

        imageView.sizeToFit()

        if let width = imageView.image?.size.width,
            let height = imageView.image?.size.height,
            width > 0, height > 0 {

            let aspectRatio = height / width

            imageView.snp.makeConstraints { maker in
                maker.top.equalToSuperview()
                maker.leading.trailing.equalTo(self).inset(16)
                maker.height.equalTo(scrollView.snp.width).multipliedBy(aspectRatio)
            }
        }

        animationView.sizeToFit()

        if let width = animationView.animation?.size.width,
            let height = animationView.animation?.size.height,
            width > 0, height > 0 {

            let aspectRatio = height / width

            animationView.snp.makeConstraints { maker in
                maker.top.equalToSuperview()
                maker.centerX.equalToSuperview()
                maker.width.equalTo(scrollView)
                maker.height.equalTo(scrollView.snp.width).multipliedBy(aspectRatio)
            }
        }

        titleLabel.snp.remakeConstraints { maker in
            maker.leading.trailing.equalTo(self).inset(16)
            maker.height.greaterThanOrEqualTo(50)
            if step.hasImage || step.hasAnimation {
                maker.top.greaterThanOrEqualTo(imageView.snp.bottom)
                maker.top.greaterThanOrEqualTo(animationView.snp.bottom)
            } else {
                maker.top.equalTo(scrollView.snp.top).offset(25)
            }
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
