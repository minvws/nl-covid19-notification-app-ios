/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import UIKit

final class EnableSettingStepView: View {
    private lazy var indexLabel = Label()
    private lazy var titleLabel = Label()
    private let actionView: EnableSettingActionView?

    private let step: EnableSettingStep
    private let stepIndex: Int

    init(theme: Theme, step: EnableSettingStep, stepIndex: Int) {
        self.step = step
        self.stepIndex = stepIndex
        self.actionView = step.action.map { EnableSettingActionView(theme: theme, action: $0) }

        super.init(theme: theme)
    }

    override func build() {
        super.build()

        indexLabel.text = "\(stepIndex)."
        indexLabel.font = theme.fonts.body
        indexLabel.textColor = theme.colors.gray
        indexLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        addSubview(indexLabel)

        titleLabel.numberOfLines = 0
        titleLabel.attributedText = step.description

        addSubview(titleLabel)

        if let actionView = actionView {
            addSubview(actionView)
        }
    }

    override func setupConstraints() {
        super.setupConstraints()

        indexLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalToSuperview().inset(16)
        }

        let hasActionView = actionView != nil

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(indexLabel.snp.top)
            make.leading.equalTo(indexLabel.snp.trailing).offset(8)
            make.trailing.equalToSuperview().inset(16)

            if !hasActionView {
                make.bottom.equalToSuperview().inset(16)
            }
        }

        if hasActionView {
            actionView?.snp.makeConstraints { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(12)
                make.leading.trailing.equalToSuperview().inset(16)
                make.bottom.equalToSuperview().inset(8)
            }
        }
    }
}
