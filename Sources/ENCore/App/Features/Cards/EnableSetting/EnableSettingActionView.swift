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
    private lazy var switchView = UIImageView(image: Image.named("Switch"))

    private let actionView: UIView?
    private let actionViewRect: CGRect
    private let action: EnableSettingStep.Action
    private let showChevron: Bool
    private let showSwitch: Bool

    init(theme: Theme, action: EnableSettingStep.Action) {
        switch action {
        case .linkCell:
            actionView = nil
            actionViewRect = CGRect(x: 0, y: 15, width: 24, height: 24)
            showChevron = false
            showSwitch = false
        case .toggle:
            actionView = UIImageView(image: Image.named("Switch"))
            actionViewRect = CGRect(x: 0, y: 20, width: 24, height: 16)
            showChevron = false
            showSwitch = false
        case .custom(image: let image, description: _, showChevron: let showChevron, showSwitch: let showSwitch):
            if let image = image {
                actionView = UIImageView(image: image)
            } else {
                actionView = nil
            }
            actionViewRect = CGRect(x: 0, y: 15, width: 24, height: 24)
            self.showChevron = showChevron
            self.showSwitch = showSwitch
        }

        self.action = action

        super.init(theme: theme)
    }

    override func build() {
        super.build()

        backgroundColor = .clear

        contentLabel.numberOfLines = 0
        contentLabel.font = theme.fonts.body
        contentLabel.text = action.content
        if case .linkCell = action {
            contentLabel.textColor = theme.colors.primary
        }

        addSubview(contentView)
        contentView.addSubview(contentLabel)

        if let actionView = actionView {
            contentView.addSubview(actionView)
        }

        if showChevron {
            contentView.addSubview(chevronView)
        }

        if showSwitch {
            contentView.addSubview(switchView)
        }

        contentView.backgroundColor = theme.colors.settingsStepBackground

        contentView.layer.masksToBounds = true
        contentView.layer.cornerRadius = 8
    }

    override func setupConstraints() {
        super.setupConstraints()

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        var leftContentAnchor = self.snp.leading

        if let actionView = actionView {
            actionView.snp.makeConstraints { make in
                make.leading.equalToSuperview().inset(16)
                make.centerY.equalToSuperview()
                make.height.equalTo(actionViewRect.height)
                make.width.equalTo(actionViewRect.width)
            }

            leftContentAnchor = actionView.snp.trailing
        }

        contentLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(16)
            make.leading.equalTo(leftContentAnchor).offset(16)
            if showSwitch {
                make.trailing.equalTo(switchView.snp.leading)
            } else if showSwitch {
                make.trailing.equalTo(chevronView.snp.leading)
            } else {
                make.trailing.equalToSuperview().inset(16)
            }
            make.bottom.equalToSuperview().inset(16)
        }

        if showChevron {
            chevronView.snp.makeConstraints { make in
                make.trailing.equalToSuperview().inset(16)
                make.centerY.equalToSuperview()
            }
        }

        if showSwitch {
            switchView.snp.makeConstraints { make in
                make.trailing.equalToSuperview().inset(16)
                make.centerY.equalToSuperview()
                make.width.equalTo(35)
                make.height.equalTo(24)
            }
        }
    }
}

private extension EnableSettingStep.Action {
    var content: String {
        switch self {
        case let .linkCell(description: description):
            return description
        case let .toggle(description: description):
            return description
        case .custom(image: _, description: let description, showChevron: _, showSwitch: _):
            return description
        }
    }
}
