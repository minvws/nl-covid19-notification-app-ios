/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import ENFoundation
import Lottie
import RxSwift
import SnapKit
import UIKit

/// @mockable
protocol StatusRouting: Routing {}

final class StatusViewController: ViewController, StatusViewControllable, CardListening {

    // MARK: - StatusViewControllable

    weak var router: StatusRouting?

    private let interfaceOrientationStream: InterfaceOrientationStreaming
    private let exposureStateStream: ExposureStateStreaming
    private let dataController: ExposureDataControlling

    private weak var listener: StatusListener?
    private weak var topAnchor: NSLayoutYAxisAnchor?

    private var disposeBag = Set<AnyCancellable>()
    private var rxDisposeBag = DisposeBag()

    private let cardBuilder: CardBuildable
    private lazy var cardRouter: Routing & CardTypeSettable = {
        cardBuilder.build(listener: self, types: [.bluetoothOff])
    }()

    private var pauseTimer: Timer?

    init(exposureStateStream: ExposureStateStreaming,
         interfaceOrientationStream: InterfaceOrientationStreaming,
         cardBuilder: CardBuildable,
         listener: StatusListener,
         theme: Theme,
         topAnchor: NSLayoutYAxisAnchor?,
         dataController: ExposureDataControlling) {
        self.exposureStateStream = exposureStateStream
        self.interfaceOrientationStream = interfaceOrientationStream
        self.dataController = dataController
        self.listener = listener
        self.topAnchor = topAnchor

        self.cardBuilder = cardBuilder

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

        showCard(false)
        addChild(cardRouter.viewControllable.uiviewController)
        cardRouter.viewControllable.uiviewController.didMove(toParent: self)

        refreshCurrentState()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateExposureStateView),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
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

        updateExposureStateView()
    }

    // MARK: - Private

    @objc private func updateExposureStateView() {

        exposureStateStream.exposureState.sink { [weak self] _ in
            self?.refreshCurrentState()
        }.store(in: &disposeBag)

        interfaceOrientationStream.isLandscape.subscribe { [weak self] _ in
            self?.refreshCurrentState()
        }.disposed(by: rxDisposeBag)
    }

    private func refreshCurrentState() {
        if let currentState = exposureStateStream.currentExposureState,
            let isLandscape = interfaceOrientationStream.currentOrientationIsLandscape {
            update(exposureState: currentState, isLandscape: isLandscape)
        }
    }

    private func updatePauseTimer() {
        if dataController.isAppPaused {
            if pauseTimer == nil {
                // This timer fires every minute to update the status on the screen. This is needed because in a paused state
                // the status will show a minute-by-minute countdown until the time when the pause state should end
                pauseTimer = Timer.scheduledTimer(withTimeInterval: .minutes(1), repeats: true, block: { [weak self] _ in
                    self?.refreshCurrentState()
                })
            }
        } else {
            pauseTimer?.invalidate()
            pauseTimer = nil
        }
    }

    private func update(exposureState status: ExposureState, isLandscape: Bool) {

        updatePauseTimer()

        let statusViewModel: StatusViewModel
        let announcementCardTypes = getAnnouncementCardTypes()
        var cardTypes = [CardType]()

        switch (status.activeState, status.notifiedState) {
        case (.active, .notNotified):
            statusViewModel = .activeWithNotNotified(showScene: !isLandscape && announcementCardTypes.isEmpty)

        case let (.inactive(.paused(pauseEndDate)), .notNotified):
            statusViewModel = .pausedWithNotNotified(theme: theme, pauseEndDate: pauseEndDate)

        case let (.active, .notified(date)):
            statusViewModel = .activeWithNotified(date: date)

        case let (.inactive(reason), .notified(date)):
            statusViewModel = StatusViewModel.activeWithNotified(date: date)
            cardTypes.append(reason.cardType(listener: listener))

        case let (.inactive(reason), .notNotified) where reason == .noRecentNotificationUpdates:
            statusViewModel = .inactiveTryAgainWithNotNotified

        case (.inactive, .notNotified):
            statusViewModel = .inactiveWithNotNotified

        case let (.authorizationDenied, .notified(date)):
            statusViewModel = .inactiveWithNotified(date: date)
            cardTypes.append(.exposureOff)

        case (.authorizationDenied, .notNotified):
            statusViewModel = .inactiveWithNotNotified

        case let (.notAuthorized, .notified(date)):
            statusViewModel = .inactiveWithNotified(date: date)
            cardTypes.append(.exposureOff)

        case (.notAuthorized, .notNotified):
            statusViewModel = .inactiveWithNotNotified
        }

        statusView.update(with: statusViewModel)

        // Add any non-status related card types and update the CardViewController via the router
        cardTypes.append(contentsOf: announcementCardTypes)
        cardRouter.types = cardTypes

        showCard(!cardTypes.isEmpty)
    }

    private func getAnnouncementCardTypes() -> [CardType] {
        var cardTypes = [CardType]()

        // Interop announcement
        if !dataController.seenAnnouncements.contains(.interopAnnouncement) {
            cardTypes.append(.interopAnnouncement)
        }

        return cardTypes
    }

    private func showCard(_ display: Bool) {
        cardRouter.viewControllable.uiviewController.view.isHidden = !display
    }

    func dismissedAnnouncement() {
        refreshCurrentState()
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

    private var iconViewSizeConstraints: Constraint?
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
    private var sceneImageHeightConstraint: NSLayoutConstraint?

    private var sceneImageAspectRatio: CGFloat {
        sceneImageView.animation.map { $0.size.height / $0.size.width } ?? 1
    }

    init(theme: Theme, cardView: UIView) {
        self.cardView = cardView

        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        /// Initially hide the status. It will become visible after the first update
        showStatus(false)

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

        sceneImageHeightConstraint = sceneImageView.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.width * sceneImageAspectRatio)
        sceneImageHeightConstraint?.isActive = true

        cloudsView.snp.makeConstraints { maker in
            maker.centerY.equalTo(iconView.snp.centerY)
            maker.leading.trailing.equalTo(stretchGuide)
        }
        sceneImageView.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalTo(stretchGuide)
            maker.centerX.equalTo(stretchGuide)
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
            iconViewSizeConstraints = maker.width.height.equalTo(48).constraint
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.frame = stretchGuide.layoutFrame
        CATransaction.commit()

        evaluateImageSize()
        evaluateHeight()
    }

    // MARK: - Internal

    func update(with viewModel: StatusViewModel) {

        iconViewSizeConstraints?.layoutConstraints.forEach { constraint in
            // if the emitter animation is not shown, we use a slightly larger main icon
            constraint.constant = viewModel.showEmitter ? 48 : 56
        }
        iconView.update(with: viewModel.icon, showEmitter: viewModel.showEmitter)
        iconView.setNeedsLayout()

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
        evaluateImageSize()

        showStatus(true)
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

    /// Manually adjusts sceneImage height constraint after layout pass
    private func evaluateImageSize() {
        sceneImageHeightConstraint?.constant = UIScreen.main.bounds.width * sceneImageAspectRatio
    }

    private func showStatus(_ show: Bool) {
        titleLabel.alpha = show ? 1 : 0
        descriptionLabel.alpha = show ? 1 : 0
        iconView.alpha = show ? 1 : 0
    }
}

private extension ExposureStateInactiveState {
    func cardType(listener: StatusListener?) -> CardType {
        switch self {
        case .paused:
            return .paused
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
