/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import UIKit

/// @mockable
protocol CardRouting: Routing {
    func route(to enableSetting: EnableSetting)
    func route(to url: URL)
    func routeToRequestExposureNotificationPermission()
    func detachEnableSetting(hideViewController: Bool)
    func detachWebview(shouldDismissViewController: Bool)
}

final class CardViewController: ViewController, CardViewControllable, Logging {
    init(listener: CardListening?,
         theme: Theme,
         types: [CardType],
         dataController: ExposureDataControlling,
         pauseController: PauseControlling) {
        self.types = types
        self.listener = listener
        self.dataController = dataController
        self.pauseController = pauseController

        super.init(theme: theme)
    }

    // MARK: - ViewController Lifecycle

    override func loadView() {
        view = stackView
        view.frame = UIScreen.main.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = nil

        recreateCards()
    }

    // MARK: - CardViewControllable

    func update(cardTypes: [CardType]) {
        types = cardTypes
    }

    func present(viewController: ViewControllable) {
        uiviewController.present(viewController.uiviewController,
                                 animated: true,
                                 completion: nil)
    }

    func present(viewController: ViewControllable, animated: Bool, inNavigationController: Bool) {
        guard inNavigationController else {
            present(viewController.uiviewController, animated: true, completion: nil)
            return
        }

        let navigationController: NavigationController

        if let navController = viewController as? NavigationController {
            navigationController = navController
        } else {
            navigationController = NavigationController(rootViewController: viewController.uiviewController, theme: theme)
        }

        if let presentationDelegate = viewController.uiviewController as? UIAdaptivePresentationControllerDelegate {
            navigationController.presentationController?.delegate = presentationDelegate
        }

        if let presentedViewController = presentedViewController {
            presentedViewController.present(navigationController, animated: true, completion: nil)
        } else {
            present(navigationController, animated: animated, completion: nil)
        }
    }

    func dismiss(viewController: ViewControllable) {
        viewController.uiviewController.dismiss(animated: true, completion: nil)
    }

    // MARK: - EnableSettingListener

    func enableSettingRequestsDismiss(shouldDismissViewController: Bool) {
        router?.detachEnableSetting(hideViewController: shouldDismissViewController)
    }

    func enableSettingDidTriggerAction() {
        router?.detachEnableSetting(hideViewController: true)
    }

    // MARK: - WebViewListener

    func webviewRequestsDismissal(shouldHideViewController: Bool) {
        router?.detachWebview(shouldDismissViewController: shouldHideViewController)
    }

    // MARK: - Private

    private func buttonAction(forAction action: CardAction?) -> () -> () {
        guard let action = action else {
            return {}
        }

        return {
            switch action {
            case .unpause:
                self.pauseController.unpauseApp()
            case let .openEnableSetting(enableSetting):
                self.router?.route(to: enableSetting)
            case let .openWebsite(url: url):
                self.router?.route(to: url)
            case let .dismissAnnouncement(announcement):
                self.dismissAnnouncement(announcement)
            case .requestExposureNotificationPermission:
                self.router?.routeToRequestExposureNotificationPermission()
            case let .custom(action: action):
                action()
            }
        }
    }

    private func dismissAnnouncement(_ announcement: Announcement) {
        var seenAnnouncements = dataController.seenAnnouncements
        seenAnnouncements.append(announcement)
        dataController.seenAnnouncements = seenAnnouncements

        listener?.dismissedAnnouncement()
    }

    private var types: [CardType] {
        didSet {
            // always recreate cards if the list contains a "dynamic" card. For instance the card with pause countdown that always needs updating
            let containsDynamicCard = types.contains(where: { self.dynamicCardTypes.contains($0) })

            if isViewLoaded, oldValue != types || containsDynamicCard {
                recreateCards()
            }
        }
    }

    private func recreateCards() {
        let existingCardViews: [CardView] = stackView.arrangedSubviews.compactMap { $0 as? CardView }
        let existingCardTypes = existingCardViews.compactMap { $0.cardType }
        let cardsToUpdate = existingCardViews.filter { self.dynamicCardTypes.contains($0.cardType) && types.contains($0.cardType) }
        let cardsToRemove = existingCardViews.filter { !types.contains($0.cardType) }
        let cardTypesToAdd = types.filter { !existingCardTypes.contains($0) }

        cardsToRemove.forEach { $0.removeFromSuperview() }

        cardsToUpdate.forEach { cardView in
            let card = cardView.cardType.card(theme: theme, pauseController: pauseController)
            cardView.update(with: card,
                            action: buttonAction(forAction: card.action),
                            secondaryAction: buttonAction(forAction: card.secondaryAction))
        }

        cardTypesToAdd.forEach { cardType in
            let card = cardType.card(theme: theme, pauseController: pauseController)
            let cardView = CardView(theme: theme, cardType: cardType)
            cardView.update(with: card,
                            action: buttonAction(forAction: card.action),
                            secondaryAction: buttonAction(forAction: card.secondaryAction))
            stackView.addArrangedSubview(cardView)
        }
    }

    weak var router: CardRouting?
    weak var listener: CardListening?
    private let dataController: ExposureDataControlling
    private let pauseController: PauseControlling
    private var pauseTimer: Timer?
    private let dynamicCardTypes: [CardType] = [.paused]

    private lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 16
        return view
    }()
}

final class CardView: View {
    private let container = UIStackView()
    private let header = UIStackView()

    private lazy var headerIconView = {
        UIImageView(image: nil)
    }()

    private let headerTitleLabel = Label()

    private let descriptionLabel = Label()
    lazy var primaryButton: Button = {
        Button(theme: self.theme)
    }()

    lazy var secondaryButton: Button = {
        Button(theme: self.theme)
    }()

    let cardType: CardType

    init(theme: Theme, cardType: CardType) {
        self.cardType = cardType
        super.init(theme: theme)
    }

    override func build() {
        super.build()

        layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        layer.cornerRadius = 12
        backgroundColor = theme.colors.cardBackground

        // container
        container.axis = .vertical
        container.spacing = 16

        // header
        header.axis = .horizontal
        header.spacing = 16
        header.alignment = .center

        // headerIconView
        header.addArrangedSubview(headerIconView)

        // headerTitleLabel
        headerTitleLabel.adjustsFontForContentSizeCategory = true
        headerTitleLabel.font = theme.fonts.title3
        headerTitleLabel.numberOfLines = 0
        headerTitleLabel.preferredMaxLayoutWidth = 200
        headerTitleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        header.addArrangedSubview(headerTitleLabel)
        container.addArrangedSubview(header)

        // descriptionLabel
        descriptionLabel.adjustsFontForContentSizeCategory = true
        descriptionLabel.font = theme.fonts.body
        descriptionLabel.numberOfLines = 0
        descriptionLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        container.addArrangedSubview(descriptionLabel)

        // primary button
        primaryButton.titleEdgeInsets = UIEdgeInsets(top: 40, left: 41, bottom: 40, right: 41)
        primaryButton.layer.cornerRadius = 8
        container.addArrangedSubview(primaryButton)

        // secondary button
        secondaryButton.titleEdgeInsets = UIEdgeInsets(top: 40, left: 41, bottom: 40, right: 41)
        secondaryButton.layer.cornerRadius = 8
        container.addArrangedSubview(secondaryButton)

        addSubview(container)
    }

    override func setupConstraints() {
        super.setupConstraints()

        container.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            container.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            container.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),

            headerIconView.widthAnchor.constraint(equalToConstant: 40),
            headerIconView.heightAnchor.constraint(equalToConstant: 40),

            primaryButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 48),
            secondaryButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 48)
        ])
    }

    func update(with card: Card, action: @escaping () -> (), secondaryAction: (() -> ())?) {
        headerIconView.image = card.icon.image
        headerTitleLabel.attributedText = card.title
        descriptionLabel.attributedText = card.message

        primaryButton.setTitle(card.actionTitle, for: .normal)
        primaryButton.style = .primary
        primaryButton.action = action

        if let secondaryAction = secondaryAction, let secondaryActionTitle = card.secondaryActionTitle {
            secondaryButton.setTitle(secondaryActionTitle, for: .normal)
            secondaryButton.style = .secondaryLight
            secondaryButton.action = secondaryAction
            secondaryButton.isHidden = false
        } else {
            secondaryButton.isHidden = true
        }
    }
}

private extension CardType {
    func card(theme: Theme, pauseController: PauseControlling) -> Card {
        switch self {
        case .paused:
            return .paused(theme: theme,
                           pauseTimeElapsed: pauseController.pauseTimeElapsed,
                           content: pauseController.getPauseCountdownString(theme: theme, emphasizeTime: false))

        case .bluetoothOff:
            return .bluetoothOff(theme: theme)
        case .exposureOff:
            return .exposureOff(theme: theme)
        case .notAuthorized:
            return .notAuthorized(theme: theme)
        case let .noInternet(retryHandler: retryHandler):
            return .noInternet(theme: theme, retryHandler: retryHandler)
        case .noInternetFor24Hours:
            return .noInternetFor24Hours(theme: theme)
        case .noLocalNotifications:
            return .noLocalNotifications(theme: theme)
        case let .notifiedMoreThanThresholdDaysAgo(date: date, explainRiskHandler: explainRiskHandler, removeNotificationHandler: removeNotificationHandler):
            return .notifiedMoreThanThresholdDaysAgo(theme: theme, date: date, explainRiskHandler: explainRiskHandler, removeNotificationHandler: removeNotificationHandler)
        }
    }
}
