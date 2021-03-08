/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import UIKit

final class OnboardingConsentSummaryStepView: View {

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        return imageView
    }()

    private lazy var label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()

    private lazy var viewsInDisplayOrder = [imageView, label]

    private var consentSummaryStep: OnboardingConsentSummaryStep

    // MARK: - Lifecycle

    init(with step: OnboardingConsentSummaryStep, theme: Theme) {
        self.consentSummaryStep = step
        super.init(theme: theme)
    }

    // MARK: - Setups

    override func build() {
        super.build()

        backgroundColor = .clear
        clipsToBounds = true
        translatesAutoresizingMaskIntoConstraints = false

        imageView.image = consentSummaryStep.image
        label.attributedText = consentSummaryStep.title

        viewsInDisplayOrder.forEach { addSubview($0) }

        isAccessibilityElement = true
        shouldGroupAccessibilityChildren = true
        accessibilityAttributedLabel = consentSummaryStep.title
    }

    override func setupConstraints() {
        super.setupConstraints()

        imageView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(-4)
            maker.leading.equalToSuperview()
            maker.size.equalTo(CGSize(width: 42, height: 51))
        }

        label.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.equalTo(imageView.snp.trailing).offset(16)
            maker.trailing.equalToSuperview()
        }

        snp.makeConstraints { maker in
            maker.height.greaterThanOrEqualTo(47)
            maker.height.greaterThanOrEqualTo(label.snp.height).offset(2)
        }
    }
}
