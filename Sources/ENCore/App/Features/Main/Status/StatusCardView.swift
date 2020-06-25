/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import UIKit

final class StatusCardView: View {
    private let container = UIStackView()
    private let header = UIStackView()

    private lazy var headerIconView = {
        UIImageView(image: nil)
    }()
    private let headerTitleLabel = Label()

    private let descriptionLabel = Label()
    private lazy var button: Button = {
        Button(theme: self.theme)
    }()

    override func build() {
        super.build()

        backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
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

    func update(with viewModel: StatusCardViewModel) {
        headerIconView.image = viewModel.icon.icon
        headerTitleLabel.attributedText = viewModel.title
        descriptionLabel.attributedText = viewModel.description

        button.setTitle(viewModel.button.title, for: .normal)
        button.style = viewModel.button.style
    }
}
