/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Lottie
import RxSwift
import UIKit

/// @mockable
protocol OnboardingConsentViewControllable: ViewControllable {}

final class OnboardingConsentStepViewController: ViewController, OnboardingConsentViewControllable, Logging {

    private lazy var skipStepButton: UIBarButtonItem = {
        let button = UIBarButtonItem()
        button.target = self
        button.title = .skipStep
        button.tintColor = self.theme.colors.primary
        button.action = #selector(skipStepButtonPressed)
        return button
    }()

    private let onboardingConsentManager: OnboardingConsentManaging
    private let consentStep: OnboardingConsentStep?
    private let interfaceOrientationStream: InterfaceOrientationStreaming
    private var disposeBag = DisposeBag()

    init(onboardingConsentManager: OnboardingConsentManaging,
         listener: OnboardingConsentListener,
         theme: Theme,
         index: Int,
         interfaceOrientationStream: InterfaceOrientationStreaming) {

        self.onboardingConsentManager = onboardingConsentManager
        self.listener = listener
        self.consentStep = self.onboardingConsentManager.getStep(index)
        self.interfaceOrientationStream = interfaceOrientationStream

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
        internalView.showVisual = !(interfaceOrientationStream.currentOrientationIsLandscape ?? false)
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
        self.internalView.playAnimation()

        interfaceOrientationStream
            .isLandscape
            .subscribe { [weak self] isLandscape in
                self?.internalView.showVisual = !isLandscape
            }.disposed(by: disposeBag)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        self.internalView.stopAnimation()
    }

    // MARK: - Functions

    @objc private func primaryButtonPressed() {
        logDebug("`primaryButtonPressed` consentstep: \(String(describing: consentStep?.step))")

        guard let consentStep = consentStep else {
            return
        }

        switch consentStep.step {
        case .en:
            if onboardingConsentManager.isNotificationAuthorizationRestricted() {
                self.listener?.displayExposureNotificationSettings()
            } else {
                onboardingConsentManager.askNotificationsAuthorization {
                    self.logDebug("after `onboardingConsentManager.askNotificationsAuthorization`")
                    self.onboardingConsentManager.askEnableExposureNotifications { activeState in
                        self.logDebug("after `onboardingConsentManager.askEnableExposureNotifications`. activeState: \(activeState)")

                        switch activeState {
                        case .notAuthorized:
                            self.closeConsent()
                        default:
                            self.goToNextStepOrCloseConsent()
                        }
                    }
                }
            }
        case .bluetooth:
            self.listener?.displayBluetoothSettings()
        case .share:
            self.listener?.displayShareApp()
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

    @objc private func skipStepButtonPressed() {
        if let consentStep = consentStep, consentStep.step == .en {
            if !onboardingConsentManager.isNotificationAuthorizationAsked() {
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

    private lazy var animationView: AnimationView = {
        let animationView = AnimationView()
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.isHidden = true
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
        label.accessibilityTraits = .header
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

    var consentStep: OnboardingConsentStep? {
        didSet {
            updateView()
            updateViewConstraints()
        }
    }

    var showVisual: Bool = true {
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

        primaryButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(safeAreaLayoutGuide).inset(16)
            maker.height.greaterThanOrEqualTo(50)

            constrainToSafeLayoutGuidesWithBottomMargin(maker: maker)
        }

        secondaryButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(safeAreaLayoutGuide).inset(16)
            maker.height.greaterThanOrEqualTo(50)

            maker.bottom.equalTo(primaryButton.snp.top).inset(-16)
        }
    }

    func playAnimation() {
        if case let .animation(_, repeatFromFrame, defaultFrame) = self.consentStep?.illustration {
            guard animationsEnabled() else {
                animationView.currentFrame = defaultFrame ?? 0
                return
            }

            if let repeatFromFrame = repeatFromFrame {
                animationView.play(fromProgress: 0, toProgress: 1, loopMode: .playOnce) { [weak self] completed in
                    if completed {
                        self?.loopAnimation(fromFrame: repeatFromFrame)
                    }
                }
            } else {
                animationView.loopMode = .loop
                animationView.play()
            }
        }
    }

    func stopAnimation() {
        animationView.stop()
    }

    private func updateView() {

        guard let step = self.consentStep else {
            return
        }

        self.titleLabel.attributedText = step.attributedTitle
        self.contentLabel.attributedText = step.attributedContent
        self.primaryButton.title = step.primaryButtonTitle

        if step.hasSecondaryButton, let title = step.secondaryButtonTitle {
            self.secondaryButton.title = title
            self.secondaryButton.isHidden = false
        }

        guard showVisual else {
            animationView.isHidden = true
            imageView.isHidden = true
            return
        }

        switch step.illustration {
        case let .image(image: image):
            imageView.image = image
            animationView.isHidden = true
            imageView.isHidden = false
        case let .animation(named: name, _, _):
            animationView.animation = LottieAnimation.named(theme.appearanceAdjustedAnimationName(name))
            animationView.isHidden = false
            imageView.isHidden = true
            playAnimation()
        case .none:
            break
        }
    }

    private func updateViewConstraints() {

        guard let step = self.consentStep else { return }

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

        var visualVisible = true
        if case .none = step.illustration {
            visualVisible = false
        } else {
            visualVisible = showVisual
        }

        titleLabel.snp.remakeConstraints { maker in
            maker.leading.trailing.equalTo(safeAreaLayoutGuide).inset(16)
            maker.height.greaterThanOrEqualTo(50)
            if !visualVisible {
                maker.top.equalTo(scrollView.snp.top).offset(25)
            } else {
                maker.top.greaterThanOrEqualTo(imageView.snp.bottom)
                maker.top.greaterThanOrEqualTo(animationView.snp.bottom)
            }
        }

        contentLabel.snp.remakeConstraints { maker in
            maker.top.equalTo(titleLabel.snp.bottom).offset(16)
            maker.leading.trailing.equalTo(safeAreaLayoutGuide).inset(16)
            maker.height.greaterThanOrEqualTo(50)
            maker.bottom.lessThanOrEqualTo(scrollView.snp.bottom)
        }

        scrollView.snp.makeConstraints { maker in
            maker.top.leading.trailing.equalTo(safeAreaLayoutGuide)
            maker.bottom.equalTo(consentStep?.hasSecondaryButton == true ? secondaryButton.snp.top : primaryButton.snp.top).inset(-16)
        }
    }

    // MARK: - Private

    private func loopAnimation(fromFrame frameNumber: Int) {
        let toFrame = animationView.animation?.endFrame ?? 0
        animationView.play(fromFrame: CGFloat(frameNumber), toFrame: toFrame, loopMode: nil) { [weak self] completed in
            if completed {
                self?.loopAnimation(fromFrame: frameNumber)
            }
        }
    }
}
