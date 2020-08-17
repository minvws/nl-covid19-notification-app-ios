/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import UIKit

final class OnboardingConsentSummaryStepsView: View {

    private let consentSummarySteps: [OnboardingConsentSummaryStep]
    private let contentView = UIStackView()

    // MARK: - Lifecycle

    required init(with steps: [OnboardingConsentSummaryStep], theme: Theme) {
        self.consentSummarySteps = steps

        super.init(theme: theme)
    }

    override func build() {
        super.build()

        backgroundColor = .clear
        clipsToBounds = true
        translatesAutoresizingMaskIntoConstraints = false

        contentView.axis = .vertical
        contentView.spacing = 16
        contentView.backgroundColor = .clear
        contentView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(contentView)

        consentSummarySteps
            .map { step in OnboardingConsentSummaryStepView(with: step, theme: theme) }
            .forEach(contentView.addArrangedSubview(_:))
    }

    override func setupConstraints() {
        super.setupConstraints()

        contentView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }
}
