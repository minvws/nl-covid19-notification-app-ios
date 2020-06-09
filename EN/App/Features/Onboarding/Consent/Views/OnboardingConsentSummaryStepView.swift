/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import UIKit

class OnboardingConsentSummaryStepView: UIView {

    lazy private var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        return imageView
    }()

    lazy private var label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()

    lazy private var viewsInDisplayOrder = [imageView, label]

    var consentSummaryStep: OnboardingConsentSummaryStep

    var estimateHeight: CGFloat {
        get {
            return (UIScreen.main.bounds.size.width - (OnboardingConsentStepViewController.onboardingConsentSummaryStepsViewLeadingMargin + OnboardingConsentStepViewController.onboardingConsentSummaryStepsViewTrailingMargin)) / 4
        }
    }
    
    // MARK: - Lifecycle

    required init(with step: OnboardingConsentSummaryStep) {

        self.consentSummaryStep = step

        super.init(frame: .zero)

        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupViews() {

        backgroundColor = .clear
        clipsToBounds = true
        translatesAutoresizingMaskIntoConstraints = false
        
        self.imageView.image = self.consentSummaryStep.image
        self.label.attributedText = self.consentSummaryStep.title
        
        for subView in viewsInDisplayOrder { addSubview(subView) }
    }

    private func setupConstraints() {

        var constraints = [[NSLayoutConstraint]()]

        constraints.append([
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            imageView.widthAnchor.constraint(equalToConstant: 28),
            imageView.heightAnchor.constraint(equalToConstant: 34)
            ])

        constraints.append([
            label.topAnchor.constraint(equalTo:  topAnchor, constant: 0),
            label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            label.heightAnchor.constraint(greaterThanOrEqualToConstant: 1)
            ])

        for constraint in constraints { NSLayoutConstraint.activate(constraint) }
    }
}
