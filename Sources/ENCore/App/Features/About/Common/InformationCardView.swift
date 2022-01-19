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

final class InformationCardView: View {

    init(theme: Theme, image: UIImage?, pretitle: NSAttributedString? = nil, title: NSAttributedString, message: NSAttributedString) {
        self.pretitleLabel = Label(frame: .zero)
        self.titleLabel = Label(frame: .zero)
        self.messageLabel = Label(frame: .zero)
        self.imageView = UIImageView(image: image)
        self.titleStackView = UIStackView(frame: .zero)

        super.init(theme: theme)

        titleStackView.axis = .vertical
        titleStackView.spacing = 8
        titleStackView.accessibilityTraits = [.header]
        titleStackView.isAccessibilityElement = true
        titleStackView.accessibilityLabel = [pretitle?.string, title.string].compactMap { $0 }.joined(separator: ". ")

        pretitleLabel.attributedText = pretitle
        pretitleLabel.isAccessibilityElement = false
        pretitleLabel.font = theme.fonts.subheadBold
        pretitleLabel.textColor = theme.colors.notified
        pretitleLabel.isHidden = pretitle == nil

        titleLabel.attributedText = title
        titleLabel.isAccessibilityElement = false
        titleLabel.font = theme.fonts.title3
        titleLabel.accessibilityTraits = .header

        messageLabel.attributedText = message
        messageLabel.font = theme.fonts.body
    }

    override var canBecomeFocused: Bool {
        return true
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        imageView.contentMode = .scaleAspectFit
        titleLabel.numberOfLines = 0
        messageLabel.numberOfLines = 0

        addSubview(imageView)
        addSubview(messageLabel)
        addSubview(titleStackView)

        titleStackView.addArrangedSubview(pretitleLabel)
        titleStackView.addArrangedSubview(titleLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()

        var imageAspectRatio: CGFloat = 0.0

        if let width = imageView.image?.size.width, let height = imageView.image?.size.height, width > 0, height > 0 {
            imageAspectRatio = height / width
        }

        imageView.snp.makeConstraints { maker in
            maker.top.leading.trailing.equalToSuperview()
            maker.height.equalTo(snp.width).multipliedBy(imageAspectRatio)
        }

        titleStackView.snp.makeConstraints { maker in
            maker.top.equalTo(imageView.snp.bottom).offset(8)
            maker.leading.trailing.equalToSuperview().inset(16)
        }

        messageLabel.snp.makeConstraints { maker in
            maker.top.equalTo(titleLabel.snp.bottom).offset(16)
            maker.leading.trailing.equalToSuperview().inset(16)

            constrainToSuperViewWithBottomMargin(maker: maker)
        }
    }

    // MARK: - Private

    private let imageView: UIImageView
    private let titleLabel: Label
    private let messageLabel: Label
    private let pretitleLabel: Label
    private let titleStackView: UIStackView
}
