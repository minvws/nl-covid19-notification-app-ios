/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import UIKit

final class CardViewController: ViewController, CardViewControllable {

    init(theme: Theme, type: CardType) {
        self.type = type

        super.init(theme: theme)
    }

    // MARK: - ViewController Lifecycle

    override func loadView() {
        self.view = internalView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        internalView.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
        internalView.update(with: type.card(theme: theme))
    }

    // MARK: - CardViewControllable

    var type: CardType {
        didSet {
            if isViewLoaded {
                internalView.update(with: type.card(theme: theme))
            }
        }
    }

    // MARK: - Private

    private lazy var internalView: CardView = CardView(theme: theme)
}

private final class CardView: View {
    private let container = UIStackView()
    private let header = UIStackView()

    private lazy var headerIconView = {
        UIImageView(image: nil)
    }()
    private let headerTitleLabel = Label()

    private let descriptionLabel = Label()
    fileprivate lazy var button: Button = {
        Button(theme: self.theme)
    }()

    override func build() {
        super.build()

        layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        layer.cornerRadius = 12

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
        button.titleEdgeInsets = UIEdgeInsets(top: 40, left: 41, bottom: 40, right: 41)
        button.layer.cornerRadius = 8
        container.addArrangedSubview(button)

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

            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 48)
        ])
    }

    func update(with card: Card) {
        headerIconView.image = Image.named("StatusInactive")
        headerTitleLabel.attributedText = card.title
        descriptionLabel.attributedText = card.message

        button.setTitle(card.actionTitle, for: .normal)
        button.style = .primary

        button.action = card.action.action
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
        }
    }
}
