/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import UIKit

final class EnableSettingActionView: View {
    private lazy var contentView = View(theme: theme)
    private lazy var contentLabel = Label()
    private lazy var chevronView = UIImageView(image: Image.named("Chevron"))

    private let actionView: UIView
    private let actionViewRect: CGRect
    private let action: EnableSettingStep.Action
    private let showChevron: Bool

    init(theme: Theme, action: EnableSettingStep.Action) {
        switch action {
        case .cell:
            actionView = UIImageView(image: Image.named("Notification"))
            actionViewRect = CGRect(x: 0, y: 15, width: 24, height: 24)
            showChevron = true
        case .toggle:
            actionView = UIImageView(image: Image.named("Switch"))
            actionViewRect = CGRect(x: 0, y: 20, width: 24, height: 16)
            showChevron = false
        }

        self.action = action

        super.init(theme: theme)
    }

    override func build() {
        super.build()

        backgroundColor = .clear

        contentLabel.numberOfLines = 0
        contentLabel.text = action.content

        addSubview(contentView)
        contentView.addSubview(contentLabel)
        contentView.addSubview(actionView)

        if showChevron {
            contentView.addSubview(chevronView)
        }

        contentView.backgroundColor = .init(red: 242.0 / 255.0,
                                            green: 242.0 / 255.0,
                                            blue: 247.0 / 255.0,
                                            alpha: 1.0)

        contentView.layer.masksToBounds = true
        contentView.layer.cornerRadius = 8
    }

    override func setupConstraints() {
        super.setupConstraints()

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        actionView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalToSuperview().inset(actionViewRect.origin.y)
            make.height.equalTo(actionViewRect.height)
            make.width.equalTo(actionViewRect.width)
        }

        contentLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(16)
            make.leading.equalTo(actionView.snp.trailing).offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(16)
        }

        if showChevron {
            chevronView.snp.makeConstraints { make in
                make.trailing.equalToSuperview().inset(16)
                make.top.equalToSuperview().inset(21)
                make.bottom.greaterThanOrEqualToSuperview().inset(21)
            }
        }
    }
}

private extension EnableSettingStep.Action {
    var content: String {
        switch self {
        case let .cell(description: description):
            return description
        case let .toggle(description: description):
            return description
        }
    }
}
