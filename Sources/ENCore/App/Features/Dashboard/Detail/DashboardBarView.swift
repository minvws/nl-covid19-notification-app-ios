/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import UIKit

final class DashboardBarView: View {

    private let percentageLabel = UILabel()
    private let titleLabel = UILabel()
    private let stackView = UIStackView()

    private let amount: Double
    private let label: String

    private let barContainerView = UIView()
    private let barFillView = UIView()

    init(theme: Theme, amount: Double, label: String) {
        self.amount = amount
        self.label = label

        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        stackView.addArrangedSubview(percentageLabel)
        stackView.addArrangedSubview(titleLabel)
        stackView.spacing = 4

        addSubview(stackView)

        let numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale.current
        numberFormatter.numberStyle = .percent
        numberFormatter.maximumFractionDigits = 1

        let percentage = numberFormatter.string(from: NSNumber(value: amount)) ?? ""
        percentageLabel.text = percentage
        percentageLabel.font = theme.fonts.caption1Bold
        percentageLabel.setContentHuggingPriority(.required, for: .horizontal)

        titleLabel.text = label
        titleLabel.font = theme.fonts.caption1
        titleLabel.textColor = theme.colors.captionGray
        titleLabel.numberOfLines = 0

        accessibilityLabel = label + ", " + percentage

        addSubview(barContainerView)
        barContainerView.layer.cornerRadius = 4
        barContainerView.backgroundColor = theme.colors.graphFill

        barFillView.layer.cornerRadius = 4
        barFillView.backgroundColor = theme.colors.graphStroke
        barContainerView.addSubview(barFillView)
    }

    override func setupConstraints() {
        stackView.snp.makeConstraints { maker in
            maker.left.equalToSuperview()
            maker.right.equalToSuperview()
            maker.top.equalToSuperview()
            maker.bottom.equalToSuperview().offset(-12)
        }

        barContainerView.snp.makeConstraints { maker in
            maker.left.equalToSuperview()
            maker.right.equalToSuperview()
            maker.bottom.equalToSuperview()
            maker.height.equalTo(8)
        }

        barFillView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.bottom.equalToSuperview()
            maker.left.equalToSuperview()
            maker.width.equalToSuperview().multipliedBy(amount)
        }
    }
}
