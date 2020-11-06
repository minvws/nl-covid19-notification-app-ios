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
    func detachEnableSetting(hideViewController: Bool)
}

final class CardViewController: ViewController, CardViewControllable, Logging {

    init(listener: CardListener?,
         theme: Theme,
         types: [CardType],
         dataController: ExposureDataControlling) {
        self.types = types
        self.listener = listener
        self.dataController = dataController

        super.init(theme: theme)
    }

    // MARK: - ViewController Lifecycle

    override func loadView() {
        self.view = stackView
        self.view.frame = UIScreen.main.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = nil

        recreateCards()
    }

    // MARK: - CardViewControllable

    func update(cardTypes: [CardType]) {
        self.types = cardTypes
    }

    func present(viewController: ViewControllable) {
        uiviewController.present(viewController.uiviewController,
                                 animated: true,
                                 completion: nil)
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

    // MARK: - Private

    private func buttonAction(forAction action: CardAction?) -> () -> () {
        guard let action = action else {
            return {}
        }

        return {
            switch action {
            case let .openEnableSetting(enableSetting):
                self.router?.route(to: enableSetting)
            case let .openWebsite(url: url):
                self.router?.route(to: url)
            case let .dismissAnnouncement(announcement):
                self.dismissAnnouncement(announcement)
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
            if isViewLoaded {
                recreateCards()
            }
        }
    }

    private func recreateCards() {

        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        types.forEach { cardType in
            let card = cardType.card(theme: theme)
            let cardView = CardView(theme: theme)
            cardView.update(with: card,
                            action: buttonAction(forAction: card.action),
                            secondaryAction: buttonAction(forAction: card.secondaryAction))
            stackView.addArrangedSubview(cardView)
        }
    }

    weak var router: CardRouting?
    weak var listener: CardListener?
    private let dataController: ExposureDataControlling

    private lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 16
        return view
    }()
}

private final class CardView: View {
    private let container = UIStackView()
    private let header = UIStackView()

    private lazy var headerIconView = {
        UIImageView(image: nil)
    }()
    private let headerTitleLabel = Label()

    private let descriptionLabel = Label()
    fileprivate lazy var primaryButton: Button = {
        Button(theme: self.theme)
    }()

    fileprivate lazy var secondaryButton: Button = {
        Button(theme: self.theme)
    }()

    override func build() {
        super.build()

        layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        layer.cornerRadius = 12
        backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)

        // container
        container.axis = .vertical
        container.spacing = 16

        //  header
        header.axis = .horizontal
        header.spacing = 16
        header.alignment = .center

        //   headerIconView
        header.addArrangedSubview(headerIconView)

        //   headerTitleLabel
        headerTitleLabel.adjustsFontForContentSizeCategory = true
        headerTitleLabel.font = theme.fonts.title3
        headerTitleLabel.numberOfLines = 0
        headerTitleLabel.preferredMaxLayoutWidth = 1000
        header.addArrangedSubview(headerTitleLabel)

        container.addArrangedSubview(header)

        //  descriptionLabel
        descriptionLabel.adjustsFontForContentSizeCategory = true
        descriptionLabel.font = theme.fonts.body
        descriptionLabel.numberOfLines = 0
        container.addArrangedSubview(descriptionLabel)

        //  button
        primaryButton.titleEdgeInsets = UIEdgeInsets(top: 40, left: 41, bottom: 40, right: 41)
        primaryButton.layer.cornerRadius = 8
        container.addArrangedSubview(primaryButton)

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
    func card(theme: Theme) -> Card {
        switch self {
        case .bluetoothOff:
            return .bluetoothOff(theme: theme)
        case .exposureOff:
            return .exposureOff(theme: theme)
        case let .noInternet(retryHandler: retryHandler):
            return .noInternet(theme: theme, retryHandler: retryHandler)
        case .noLocalNotifications:
            return .noLocalNotifications(theme: theme)
        case .interopAnnouncement:
            return .interopAnnouncement(theme: theme)
        }
    }
}
