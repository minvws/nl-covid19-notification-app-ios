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
        super.init(theme: theme)

        pretitleLabel.attributedText = pretitle
        pretitleLabel.font = theme.fonts.subheadBold
        pretitleLabel.textColor = theme.colors.notified

        titleLabel.attributedText = title
        titleLabel.font = theme.fonts.title3
        titleLabel.accessibilityTraits = .header

        messageLabel.attributedText = message
        messageLabel.font = theme.fonts.body
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        imageView.contentMode = .scaleAspectFit
        titleLabel.numberOfLines = 0
        messageLabel.numberOfLines = 0

        addSubview(imageView)
        addSubview(pretitleLabel)
        addSubview(titleLabel)
        addSubview(messageLabel)
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

        pretitleLabel.snp.makeConstraints { maker in
            let offset = pretitleLabel.attributedText?.length == 0 ? 0 : 8
            maker.top.equalTo(imageView.snp.bottom).offset(offset)
            maker.leading.trailing.equalToSuperview().inset(16)
        }

        titleLabel.snp.makeConstraints { maker in
            maker.top.equalTo(pretitleLabel.snp.bottom).offset(8)
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
}
