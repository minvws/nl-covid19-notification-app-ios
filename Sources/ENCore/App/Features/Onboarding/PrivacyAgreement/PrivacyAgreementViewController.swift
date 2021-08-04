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
            OnboardingConsentSummaryStep(theme: theme, title: .privacyAgreementStep0, image: .privacyShield),
            OnboardingConsentSummaryStep(theme: theme, title: .privacyAgreementStep1, image: .bluetoothShield),
            OnboardingConsentSummaryStep(theme: theme, title: .privacyAgreementStep2, image: .bluetoothShield),
            OnboardingConsentSummaryStep(theme: theme, title: .privacyAgreementStep4, image: .bluetoothShield),
            OnboardingConsentSummaryStep(theme: theme, title: .consentStep1Summary2, image: .lockShield),
            OnboardingConsentSummaryStep(theme: theme, title: .consentStep1Summary3, image: .lockShield),
            OnboardingConsentSummaryStep(theme: theme, title: .privacyAgreementStep3, image: .bellShield)
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

    lazy var privacyAgreementButton: CheckmarkButton = {
        let button = CheckmarkButton(theme: theme)
        button.accessibilityLabel = .privacyAgreementConsentButton
        button.label.text = .privacyAgreementConsentButton
        return button
    }()

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

    lazy var stepsTitleLabel: Label = {
        let label = Label(frame: .zero)
        label.isUserInteractionEnabled = true
        label.font = theme.fonts.body
        label.textColor = theme.colors.gray
        label.text = .privacyAgreementStepsTitle
        label.numberOfLines = 0
        label.accessibilityTraits = .header
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
        scrollView.addSubview(stepsTitleLabel)

        stepViews.enumerated().forEach { index, stepView in
            stackView.addListSubview(stepView, index: index, total: stepViews.count)
        }

        bottomStackView.addArrangedSubview(privacyAgreementButton)
        bottomStackView.addArrangedSubview(nextButton)

        addSubview(scrollView)
        addSubview(bottomStackView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        hasBottomMargin = true

        scrollView.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(safeAreaLayoutGuide)
            maker.top.equalToSuperview()
            maker.bottom.equalTo(bottomStackView.snp.top)
        }

        titleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.top.equalToSuperview().inset(16)
        }

        readPrivacyAgreementLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(16)
            maker.top.equalTo(titleLabel.snp.bottom).offset(16)
        }

        stepsTitleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(16)
            maker.top.equalTo(readPrivacyAgreementLabel.snp.bottom).offset(5)
        }

        stackView.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.width.equalToSuperview().inset(16)
            maker.top.equalTo(readPrivacyAgreementLabel.snp.bottom).offset(40)
        }

        bottomStackView.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(safeAreaLayoutGuide).inset(16)
            constrainToSafeLayoutGuidesWithBottomMargin(maker: maker)
        }

        nextButton.snp.makeConstraints { maker in
            maker.height.greaterThanOrEqualTo(50)
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
