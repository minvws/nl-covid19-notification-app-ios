/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import UIKit

final class UpdateInstructionsViewController: UIViewController {

    // MARK: - Lifecycle

    override func loadView() {
        self.view = internalView
        self.view.frame = UIScreen.main.bounds
    }

    // MARK: - Private

    private let steps: [UpdateStep] = [
        UpdateStep(title: localizedString(for: "update.software.os.detail.step1"),
                   settingsStep: SettingsInformationStep(message: localizedString(for: "update.software.os.detail.step1.detail"),
                                                         leftIcon: UIImage(named: "SettingsIcon"),
                                                         showBadgeIcon: false)),
        UpdateStep(title: localizedString(for: "update.software.os.detail.step2"),
                   settingsStep: SettingsInformationStep(message: localizedString(for: "update.software.os.detail.step2.detail"),
                                                         leftIcon: UIImage(named: "SettingsPlain"),
                                                         showBadgeIcon: true)),
        UpdateStep(title: localizedString(for: "update.software.os.detail.step3"),
                   settingsStep: SettingsInformationStep(message: localizedString(for: "update.software.os.detail.step3.detail"),
                                                         leftIcon: nil,
                                                         showBadgeIcon: true)),
        UpdateStep(title: localizedString(for: "update.software.os.detail.step4"), settingsStep: nil)
    ]

    private lazy var internalView: UpdateInstructionsView = UpdateInstructionsView(steps: steps)
}

// MARK: - Functions

final class UpdateInstructionsView: UIView {

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = font(size: 28, weight: .bold, textStyle: .title2)
        label.text = localizedString(for: "update.software.os.detail.title")
        return label
    }()

    // MARK: - Life cycle

    init(steps: [UpdateStep]) {
        self.steps = steps
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = .white
        addSubview(stackView)
        stackView.addArrangedSubview(titleLabel)

        steps.forEach { stackView.addArrangedSubview(UpdateStepView(step: $0)) }
    }

    private func setupConstraints() {
        var constraints = [[NSLayoutConstraint]()]

        constraints.append([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 16)
        ])

        constraints.forEach { NSLayoutConstraint.activate($0) }
    }

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 32
        stackView.backgroundColor = .clear
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private let steps: [UpdateStep]
}

final class UpdateStepView: UIStackView {

    init(step: UpdateStep) {
        self.step = step
        super.init(frame: .zero)

        setupViews()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        axis = .vertical
        alignment = .fill
        distribution = .fill
        spacing = 12
        backgroundColor = .clear

        titleLabel.text = step.title
        addArrangedSubview(titleLabel)

        if let settingsStep = step.settingsStep {
            addArrangedSubview(SettingsInformationStepView(informationStep: settingsStep))
        }
    }

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = font(size: 17, weight: .regular, textStyle: .body)
        return label
    }()

    private let step: UpdateStep
}

final class SettingsInformationStepView: UIView {

    init(informationStep: SettingsInformationStep) {
        self.informationStep = informationStep
        super.init(frame: .zero)

        setupViews()
        setupConstraints()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1.00)
        layer.cornerRadius = 8
        addSubview(stackView)

        if let leftIconImage = informationStep.leftIcon {
            leftIconView.image = leftIconImage
            stackView.addArrangedSubview(leftIconView)
        }

        titleLabel.text = informationStep.message
        stackView.addArrangedSubview(titleLabel)

        if informationStep.showBadgeIcon {
            stackView.addArrangedSubview(badgeIconView)
            stackView.addArrangedSubview(disclosureIndicator)
        }
    }

    private func setupConstraints() {
        var constraints = [[NSLayoutConstraint]()]

        constraints.append([
            heightAnchor.constraint(equalToConstant: 56),
            leftIconView.widthAnchor.constraint(equalToConstant: 24),
            leftIconView.heightAnchor.constraint(equalToConstant: 24),
            badgeIconView.widthAnchor.constraint(equalToConstant: 24),
            badgeIconView.heightAnchor.constraint(equalToConstant: 24),
            disclosureIndicator.widthAnchor.constraint(equalToConstant: 8),
            disclosureIndicator.heightAnchor.constraint(equalToConstant: 14),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stackView.centerYAnchor.constraint(equalToSystemSpacingBelow: centerYAnchor, multiplier: 0)
        ])

        constraints.forEach { NSLayoutConstraint.activate($0) }
    }

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 16
        stackView.backgroundColor = .clear
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = font(size: 17, weight: .regular, textStyle: .body)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return label
    }()

    private lazy var leftIconView: UIImageView = UIImageView()

    private lazy var badgeIconView: UIImageView = {
        return UIImageView(image: UIImage(named: "RedBadge"))
    }()

    private lazy var disclosureIndicator: UIImageView = {
        return UIImageView(image: UIImage(named: "Chevron"))
    }()

    private let informationStep: SettingsInformationStep
}

struct UpdateStep {
    let title: String
    let settingsStep: SettingsInformationStep?
}

struct SettingsInformationStep {
    let message: String
    let leftIcon: UIImage?
    let showBadgeIcon: Bool
}
