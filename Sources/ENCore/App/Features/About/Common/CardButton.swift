/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import SnapKit
import UIKit

final class CardButton: Button {

    enum CardType {
        case short, long
    }

    init(title: String, subtitle: String, image: UIImage?, type: CardButton.CardType = .short, theme: Theme) {
        self.cardImageView = UIImageView(image: image)

        if Localization.isRTL {
            self.cardImageView.transform = CGAffineTransform(scaleX: -1, y: 1)
        } else {
            self.cardImageView.transform = .identity
        }

        self.cardType = type
        super.init(theme: theme)

        cardTitleLabel.text = title
        subtitleLabel.text = subtitle

        build()
        setupConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented. Use designated CardButton init instead.")
    }

    required init(title: String = "", theme: Theme) {
        fatalError("init(title:theme:) has not been implemented. Use designated CardButton init instead.")
    }

    // MARK: - Private

    private let cardTitleLabel = Label(frame: .zero)
    private let subtitleLabel = Label(frame: .zero)
    private let cardImageView: UIImageView
    private let cardType: CardButton.CardType

    private func build() {
        cardImageView.contentMode = .scaleAspectFit
        cardTitleLabel.numberOfLines = 0
        cardTitleLabel.font = theme.fonts.title3
        subtitleLabel.numberOfLines = 0
        subtitleLabel.lineBreakMode = .byWordWrapping
        subtitleLabel.font = theme.fonts.body

        addSubview(cardTitleLabel)
        addSubview(subtitleLabel)
        addSubview(cardImageView)
    }

    private func setupConstraints() {

        cardTitleLabel.snp.makeConstraints { maker in
            maker.leading.top.equalToSuperview().inset(16)

            let trailingConstraint = cardType == .short ? cardImageView.snp.leading : snp.trailing
            maker.trailing.equalTo(trailingConstraint).inset(16)
        }

        subtitleLabel.snp.makeConstraints { maker in
            maker.top.equalTo(cardTitleLabel.snp.bottom).offset(6)
            maker.leading.equalToSuperview().inset(16)

            let trailingConstraint = cardType == .short ? cardImageView.snp.leading : snp.trailing
            maker.trailing.equalTo(trailingConstraint).inset(16)

            if cardType == .short {
                maker.bottom.equalToSuperview().inset(16)
            }
        }

        let imageAspectRatio = cardImageView.image?.aspectRatio ?? 1.0

        cardImageView.snp.makeConstraints { maker in
            maker.bottom.equalToSuperview()

            if cardType == .short {
                maker.width.equalTo(78 * imageAspectRatio)
                maker.height.equalTo(78)
                maker.trailing.equalToSuperview()
            } else {
                maker.leading.trailing.equalToSuperview().inset(16)
                maker.top.equalTo(subtitleLabel.snp.bottom).offset(4)
                maker.height.equalTo(cardImageView.snp.width).dividedBy(imageAspectRatio)
            }
        }

        snp.makeConstraints { maker in
            maker.height.greaterThanOrEqualTo(80)
        }
    }
}
