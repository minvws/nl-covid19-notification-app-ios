/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import ENFoundation
import Lottie
import SnapKit
import UIKit

/// @mockable
protocol StatusRouting: Routing {}

final class StatusViewController: ViewController, StatusViewControllable {

    // MARK: - StatusViewControllable

    weak var router: StatusRouting?

    private let exposureStateStream: ExposureStateStreaming
    private weak var listener: StatusListener?
    private weak var topAnchor: NSLayoutYAxisAnchor?

    private var exposureStateStreamCancellable: AnyCancellable?

    private let cardBuilder: CardBuildable
    private var cardRouter: Routing & CardTypeSettable

    init(exposureStateStream: ExposureStateStreaming,
         cardBuilder: CardBuildable,
         listener: StatusListener,
         theme: Theme,
         topAnchor: NSLayoutYAxisAnchor?) {
        self.exposureStateStream = exposureStateStream
        self.listener = listener
        self.topAnchor = topAnchor

        self.cardBuilder = cardBuilder
        self.cardRouter = cardBuilder.build(type: .bluetoothOff)

        super.init(theme: theme)
    }

    // MARK: - View Lifecycle

    override func loadView() {
        self.view = statusView
        self.view.frame = UIScreen.main.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        statusView.listener = listener

        addChild(cardRouter.viewControllable.uiviewController)
        cardRouter.viewControllable.uiviewController.didMove(toParent: self)

        if let currentState = exposureStateStream.currentExposureState {
            update(exposureState: currentState)
        }
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)

        // Ties the top anchor of the view to the top anchor of the main view (outside of the scroll view)
        // to make the view stretch while rubber banding
        if let topAnchor = topAnchor {
            statusView.stretchGuide.topAnchor.constraint(equalTo: topAnchor)
                .withPriority(.defaultHigh - 100)
                .isActive = true
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        exposureStateStreamCancellable = exposureStateStream.exposureState.sink { [weak self] status in
            guard let strongSelf = self else {
                return
            }

            strongSelf.update(exposureState: status)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(false)

        exposureStateStreamCancellable = nil
    }

    // MARK: - Private

    private func update(exposureState status: ExposureState) {
        let statusViewModel: StatusViewModel

        switch (status.activeState, status.notifiedState) {
        case (.active, .notNotified):
            statusViewModel = .activeWithNotNotified
        case let (.active, .notified(date)):
            statusViewModel = .activeWithNotified(date: date)
        case let (.inactive(reason), .notified(date)):
            let cardType = reason.cardType(listener: listener)

            statusViewModel = StatusViewModel.activeWithNotified(date: date).with(cardType: cardType)
        case let (.inactive(reason), .notNotified) where reason == .noRecentNotificationUpdates:
            statusViewModel = .inactiveTryAgainWithNotNotified
        case (.inactive, .notNotified):
            statusViewModel = .inactiveWithNotNotified
        case let (.authorizationDenied, .notified(date)):
            statusViewModel = StatusViewModel
                .inactiveWithNotified(date: date)
                .with(cardType: .exposureOff)
        case (.authorizationDenied, .notNotified):
            statusViewModel = .inactiveWithNotNotified
        case let (.notAuthorized, .notified(date)):
            statusViewModel = StatusViewModel
                .inactiveWithNotified(date: date)
                .with(cardType: .exposureOff)
        case (.notAuthorized, .notNotified):
            statusViewModel = .inactiveWithNotNotified
        }

        statusView.update(with: statusViewModel)

        if let cardType = statusViewModel.cardType {
            cardRouter.type = cardType
            cardRouter.viewControllable.uiviewController.view.isHidden = false
        } else {
            cardRouter.viewControllable.uiviewController.view.isHidden = true
        }
    }

    private lazy var statusView: StatusView = StatusView(theme: self.theme,
                                                         cardView: cardRouter.viewControllable.uiviewController.view)
}

private final class StatusView: View {

    weak var listener: StatusListener?

    fileprivate let stretchGuide = UILayoutGuide() // grows larger while stretching, grows all visible elements
    private let contentStretchGuide = UILayoutGuide() // grows larger while stretching, used to center the content

    private let contentContainer = UIStackView()
    private let textContainer = UIStackView()
    private let buttonContainer = UIStackView()
    private let cardView: UIView
    private lazy var iconView: EmitterStatusIconView = {
        EmitterStatusIconView(theme: self.theme)
    }()

    private let titleLabel = Label()
    private let descriptionLabel = Label()

    private let gradientLayer = CAGradientLayer()
    private lazy var cloudsView = CloudView(theme: theme)
    private lazy var sceneImageView = StatusAnimationView(theme: theme)

    private var containerToSceneVerticalConstraint: NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?

    init(theme: Theme, cardView: UIView) {
        self.cardView = cardView

        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        contentContainer.axis = .vertical
        contentContainer.spacing = 32
        contentContainer.alignment = .center

        textContainer.axis = .vertical
        textContainer.spacing = 16

        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.font = theme.fonts.title2
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.accessibilityTraits = .header

        descriptionLabel.adjustsFontForContentSizeCategory = true
        descriptionLabel.font = theme.fonts.body
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        descriptionLabel.textColor = theme.colors.gray

        buttonContainer.axis = .vertical
        buttonContainer.spacing = 16

        layer.addSublayer(gradientLayer)
        textContainer.addArrangedSubview(titleLabel)
        textContainer.addArrangedSubview(descriptionLabel)
        contentContainer.addArrangedSubview(iconView)
        contentContainer.addArrangedSubview(textContainer)
        contentContainer.addArrangedSubview(buttonContainer)
        contentContainer.addArrangedSubview(cardView)
        addSubview(cloudsView)
        addSubview(sceneImageView)
        addSubview(contentContainer)
        addLayoutGuide(contentStretchGuide)
        addLayoutGuide(stretchGuide)
    }

    override func setupConstraints() {
        super.setupConstraints()

        cloudsView.translatesAutoresizingMaskIntoConstraints = false
        sceneImageView.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.translatesAutoresizingMaskIntoConstraints = false

        containerToSceneVerticalConstraint = sceneImageView.topAnchor.constraint(equalTo: contentStretchGuide.bottomAnchor, constant: -48)
        heightConstraint = heightAnchor.constraint(equalToConstant: 0).withPriority(.defaultHigh + 100)

        let sceneImageAspectRatio = sceneImageView.animation.map { $0.size.width / $0.size.height } ?? 1

        cloudsView.snp.makeConstraints { maker in
            maker.centerY.equalTo(iconView.snp.centerY)
            maker.leading.trailing.equalTo(stretchGuide)
        }
        sceneImageView.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalTo(stretchGuide)
            maker.width.equalTo(sceneImageView.snp.height).multipliedBy(sceneImageAspectRatio)
            maker.height.equalTo(300)
        }
        stretchGuide.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(contentStretchGuide).inset(-16)

            maker.top.equalTo(contentStretchGuide).inset(-70)
            maker.bottom.greaterThanOrEqualTo(contentStretchGuide.snp.bottom)
            maker.leading.trailing.bottom.equalToSuperview()
            maker.top.equalToSuperview().priority(.low)
        }
        contentStretchGuide.snp.makeConstraints { maker in
            maker.leading.trailing.centerY.equalTo(contentContainer)
            maker.height.greaterThanOrEqualTo(contentContainer.snp.height)
            maker.bottom.equalTo(stretchGuide.snp.bottom).priority(.high)
        }
        iconView.snp.makeConstraints { maker in
            maker.width.height.equalTo(48)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.frame = stretchGuide.layoutFrame
        CATransaction.commit()

        evaluateHeight()
    }

    // MARK: - Internal

    func update(with viewModel: StatusViewModel) {
        iconView.update(with: viewModel.icon)

        titleLabel.attributedText = viewModel.title
        descriptionLabel.attributedText = viewModel.description

        buttonContainer.subviews.forEach { $0.removeFromSuperview() }
        for buttonModel in viewModel.buttons {
            let button = Button(title: buttonModel.title, theme: theme)
            button.contentEdgeInsets = UIEdgeInsets(top: 14, left: 24, bottom: 14, right: 24)
            button.style = buttonModel.style
            button.rounded = true
            button.action = { [weak self] in
                self?.listener?.handleButtonAction(buttonModel.action)
            }
            buttonContainer.addArrangedSubview(button)
        }
        buttonContainer.isHidden = viewModel.buttons.isEmpty

        gradientLayer.colors = [theme.colors[keyPath: viewModel.gradientColor].cgColor, UIColor.white.withAlphaComponent(0).cgColor]

        sceneImageView.isHidden = !viewModel.showScene
        containerToSceneVerticalConstraint?.isActive = viewModel.showScene
        cloudsView.isHidden = !viewModel.showClouds

        evaluateHeight()
    }

    // MARK: - Private

    /// Calculates the desired height for the current content
    /// This is required for stretching
    private func evaluateHeight() {
        guard bounds.width > 0 else { return }

        heightConstraint?.isActive = false
        let size = systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        heightConstraint?.constant = size.height
        heightConstraint?.isActive = true
    }
}

private extension ExposureStateInactiveState {
    func cardType(listener: StatusListener?) -> CardType {
        switch self {
        case .bluetoothOff:
            return .bluetoothOff
        case .disabled:
            return .exposureOff
        case .noRecentNotificationUpdates:
            return .noInternet(retryHandler: {
                listener?.handleButtonAction(.tryAgain)
            })
        case .pushNotifications:
            return .noLocalNotifications
        }
    }
}

private final class StatusAnimationView: View {
    private lazy var animationView = AnimationView()
    fileprivate var animation: Animation? { animationView.animation }

    deinit {
        replayTimer?.invalidate()
        replayTimer = nil
    }

    override func build() {
        super.build()
        backgroundColor = .clear

        animationView.animation = LottieAnimation.named("statusactive")
        animationView.loopMode = .playOnce

        playAnimation()

        addSubview(animationView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        animationView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - Private

    private var replayTimer: Timer?

    private func scheduleReplayTimer() {
        replayTimer?.invalidate()

        let randomDelay = arc4random_uniform(5) + 10
        replayTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(randomDelay),
                                           repeats: false,
                                           block: { [weak self] _ in
                                               self?.playAnimation()
            })
    }

    private func playAnimation() {
        #if DEBUG

            if let animationsEnabled = AnimationTestingOverrides.animationsEnabled, !animationsEnabled {
                return
            }

        #endif

        if animationsEnabled() {
            animationView.play { [weak self] _ in
                self?.scheduleReplayTimer()
            }
        }
    }
}
