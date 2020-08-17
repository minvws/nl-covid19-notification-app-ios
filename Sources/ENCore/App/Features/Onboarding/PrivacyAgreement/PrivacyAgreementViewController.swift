/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import SafariServices
import SnapKit
import UIKit

final class PrivacyAgreementViewController: ViewController, Logging {

    init(listener: PrivacyAgreementListener, theme: Theme) {
        self.listener = listener
        informationSteps = [
            OnboardingConsentSummaryStep(theme: theme, title: .privacyAgreementStep1, image: .lockShield),
            OnboardingConsentSummaryStep(theme: theme, title: .privacyAgreementStep2, image: .lockShield),
            OnboardingConsentSummaryStep(theme: theme, title: .privacyAgreementStep3, image: .lockShield),
            OnboardingConsentSummaryStep(theme: theme, title: .privacyAgreementStep4, image: .lockShield)
        ]
        super.init(theme: theme)
    }

    // MARK: - ViewController Lifecycle

    override func loadView() {
        self.view = internalView
        self.view.frame = UIScreen.main.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        internalView.privacyAgreementButton.addTarget(self, action: #selector(didPressAgreeWithPrivacyAgreementButton), for: .touchUpInside)

        internalView.nextButton.addTarget(self, action: #selector(didTapNextButton), for: .touchUpInside)

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapReadPrivacyAgreementLabel))
        internalView.readPrivacyAgreementLabel.addGestureRecognizer(tapRecognizer)
    }

    @objc func didTapNextButton() {
        listener?.privacyAgreementDidComplete()
    }

    @objc func didPressAgreeWithPrivacyAgreementButton() {
        let newAcceptValue = !internalView.privacyAgreementButton.isSelected

        internalView.privacyAgreementButton.isSelected = newAcceptValue
        internalView.nextButton.isEnabled = newAcceptValue
    }

    @objc func didTapReadPrivacyAgreementLabel() {
        guard let url = URL(string: .helpPrivacyPolicyLink) else {
            return logError("Cannot create URL from: \(String.helpPrivacyPolicyLink)")
        }
        listener?.privacyAgreementRequestsRedirect(to: url)
    }

    private let informationSteps: [OnboardingConsentSummaryStep]
    private weak var listener: PrivacyAgreementListener?
    private lazy var internalView = PrivacyAgreementView(theme: self.theme, informationSteps: informationSteps)
}

private final class PrivacyAgreementView: View {

    lazy var privacyAgreementButton = PrivacyAgreementButton(theme: theme)

    lazy var nextButton: Button = {
        let button = Button(theme: theme)
        button.setTitle(.nextButtonTitle, for: .normal)
        button.isEnabled = false
        return button
    }()

    lazy var readPrivacyAgreementLabel: Label = {
        let label = Label(frame: .zero)
        label.isUserInteractionEnabled = true
        label.attributedText = attributedSubtitleString
        label.numberOfLines = 0
        return label
    }()

    init(theme: Theme, informationSteps: [OnboardingConsentSummaryStep]) {
        self.stepViews = informationSteps.map { OnboardingConsentSummaryStepView(with: $0, theme: theme) }
        super.init(theme: theme)
    }

    override func build() {
        super.build()

        scrollView.addSubview(stackView)
        scrollView.addSubview(titleLabel)
        scrollView.addSubview(readPrivacyAgreementLabel)

        stepViews.forEach { stackView.addArrangedSubview($0) }

        bottomStackView.addArrangedSubview(privacyAgreementButton)
        bottomStackView.addArrangedSubview(nextButton)

        addSubview(scrollView)
        addSubview(bottomStackView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        hasBottomMargin = true

        scrollView.snp.makeConstraints { maker in
            maker.leading.trailing.top.equalToSuperview()
            maker.bottom.equalTo(bottomStackView.snp.top)
        }

        titleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.top.equalToSuperview().inset(16)
        }

        readPrivacyAgreementLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(16)
            maker.top.equalTo(titleLabel.snp.bottom).offset(16)
        }

        stackView.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.width.equalToSuperview().inset(16)
            maker.top.equalTo(readPrivacyAgreementLabel.snp.bottom).offset(40)
        }

        bottomStackView.snp.makeConstraints { maker in
            maker.leading.trailing.width.equalToSuperview().inset(16)
            constrainToSafeLayoutGuidesWithBottomMargin(maker: maker)
        }

        nextButton.snp.makeConstraints { maker in
            maker.height.equalTo(50)
        }
    }

    // MARK: - Private

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(frame: .zero)
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.backgroundColor = .clear
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private lazy var titleLabel: Label = {
        let titleLabel = Label(frame: .zero)
        titleLabel.numberOfLines = 0
        titleLabel.font = theme.fonts.largeTitle
        titleLabel.accessibilityTraits = .header
        titleLabel.text = String.privacyAgreementTitle
        return titleLabel
    }()

    private let bottomStackView: UIStackView = {
        let stackView = UIStackView(frame: .zero)
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.backgroundColor = .clear
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private lazy var attributedSubtitleString: NSAttributedString = {
        let attributtedString = String(format: .privacyAgreementMessage, String.privacyAgreementMessageLink).attributed()
        let linkRange = (attributtedString.string as NSString).range(of: .privacyAgreementMessageLink)

        attributtedString.addAttributes([.font: theme.fonts.body, .foregroundColor: theme.colors.gray],
                                        range: NSRange(location: 0, length: attributtedString.string.count))

        attributtedString.addAttributes([
            .foregroundColor: theme.colors.primary,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .font: theme.fonts.bodyBold
        ],
        range: linkRange)
        return attributtedString
    }()

    private let scrollView = UIScrollView(frame: .zero)
    private let stepViews: [OnboardingConsentSummaryStepView]
}

private final class PrivacyAgreementButton: Button {
    required init(theme: Theme) {
        super.init(theme: theme)
        isSelected = false
        style = .tertiary
        build()
        setupContraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(title: String = "", theme: Theme) {
        fatalError("init(title:theme:) has not been implemented")
    }

    override var isSelected: Bool {
        didSet {
            checkmark.image = isSelected ? .checkmarkChecked : .checkmarkUnchecked
        }
    }

    private func build() {
        addSubview(label)
        addSubview(checkmark)
    }

    private func setupContraints() {
        checkmark.snp.makeConstraints { maker in
            maker.width.height.equalTo(28)
            maker.leading.equalToSuperview().inset(16)
            maker.centerY.equalToSuperview()
        }

        label.snp.makeConstraints { maker in
            maker.leading.equalTo(checkmark.snp.trailing).offset(16)
            maker.trailing.top.bottom.equalToSuperview().inset(16)
        }
    }

    private lazy var checkmark = UIImageView(image: .checkmarkUnchecked)

    private lazy var label: Label = {
        let label = Label(frame: .zero)
        label.numberOfLines = 0
        label.textColor = theme.colors.gray
        label.font = theme.fonts.subhead
        label.text = String.privacyAgreementConsentButton
        return label
    }()
}
