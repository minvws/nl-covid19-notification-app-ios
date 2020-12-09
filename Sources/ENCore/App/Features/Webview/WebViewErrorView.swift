/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

final class WebViewErrorView: View {

    private lazy var contentContainer: UIView = {
        UIView()
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 32
        stackView.alignment = .center

        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)

        return stackView
    }()

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = .loadingError
        imageView.contentMode = .scaleAspectFit
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return imageView
    }()

    private lazy var titleLabel: Label = {
        let label = Label()
        label.text = .webviewLoadingFailedTitle
        label.font = theme.fonts.title2
        label.accessibilityTraits = .header
        label.numberOfLines = 0
        return label
    }()

    private lazy var subtitleLabel: Label = {
        let label = Label()
        label.text = .webviewLoadingFailedSubTitle
        label.font = theme.fonts.body
        label.textColor = theme.colors.gray
        label.accessibilityTraits = .staticText
        label.numberOfLines = 0
        return label
    }()

    lazy var actionButton: Button = {
        let button = Button(theme: theme)
        button.style = .primary
        button.setTitle(.webviewLoadingFailedTryAgain, for: .normal)
        return button
    }()

    override func build() {
        super.build()
        addSubview(contentContainer)
        contentContainer.addSubview(stackView)
        addSubview(actionButton)
    }

    override func setupConstraints() {
        super.setupConstraints()

        hasBottomMargin = true

        contentContainer.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(34)
            maker.top.equalToSuperview().offset(16)
            maker.bottom.equalTo(actionButton.snp.top).offset(-16)
        }

        stackView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.centerY.equalToSuperview().priority(.low)
            maker.top.greaterThanOrEqualToSuperview()
            maker.bottom.lessThanOrEqualToSuperview()
        }

        imageView.snp.makeConstraints { maker in
            maker.width.equalTo(self).multipliedBy(0.6)
        }

        titleLabel.snp.makeConstraints { maker in
            maker.width.equalTo(stackView)
        }

        subtitleLabel.snp.makeConstraints { maker in
            maker.width.equalTo(stackView)
        }

        actionButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(safeAreaLayoutGuide).inset(16)
            maker.height.equalTo(50)

            constrainToSafeLayoutGuidesWithBottomMargin(maker: maker)
        }
    }
}
