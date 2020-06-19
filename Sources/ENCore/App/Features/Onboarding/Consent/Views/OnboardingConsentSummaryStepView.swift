/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

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

    var estimateHeight: CGFloat {
        return (UIScreen.main.bounds.size.width - (OnboardingConsentStepViewController.onboardingConsentSummaryStepsViewLeadingMargin + OnboardingConsentStepViewController.onboardingConsentSummaryStepsViewTrailingMargin)) / 4
    }

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

        self.imageView.image = self.consentSummaryStep.image
        self.label.attributedText = self.consentSummaryStep.title

        viewsInDisplayOrder.forEach { addSubview($0) }
    }

    override func setupConstraints() {
        super.setupConstraints()

        var constraints = [[NSLayoutConstraint]()]

        imageView.constraints.forEach { imageView.removeConstraint($0) }
        label.constraints.forEach { label.removeConstraint($0) }

        constraints.append([
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            imageView.widthAnchor.constraint(equalToConstant: 28),
            imageView.heightAnchor.constraint(equalToConstant: 34)
        ])

        constraints.append([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            label.heightAnchor.constraint(greaterThanOrEqualToConstant: 1)
        ])

        for constraint in constraints { NSLayoutConstraint.activate(constraint) }
    }
}
