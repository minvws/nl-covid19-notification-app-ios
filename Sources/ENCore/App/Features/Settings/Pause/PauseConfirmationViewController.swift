/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import UIKit

/// @mockable
protocol PauseConfirmationViewControllable: ViewControllable {}

final class PauseConfirmationViewController: ViewController, PauseConfirmationViewControllable {

    // MARK: - PauseConfirmationViewControllable

    weak var listener: PauseConfirmationListener?

    init(theme: Theme,
         listener: PauseConfirmationListener,
         pauseController: PauseControlling) {

        self.listener = listener
        self.pauseController = pauseController

        super.init(theme: theme)

        modalPresentationStyle = .popover
        navigationItem.rightBarButtonItem = closeBarButtonItem
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = .moreInformationSettingsPauseTitle

        internalView.checkmarkButton.addTarget(self, action: #selector(didPressHideScreenButton), for: .touchUpInside)
        internalView.confirmButton.addTarget(self, action: #selector(didPressConfirmButton), for: .touchUpInside)
        internalView.cancelButton.addTarget(self, action: #selector(didPressCancelButton), for: .touchUpInside)
    }

    override func loadView() {
        self.view = internalView
        self.view.frame = UIScreen.main.bounds
    }

    @objc func didPressHideScreenButton() {
        let newAcceptValue = !internalView.checkmarkButton.isSelected

        internalView.checkmarkButton.isSelected = newAcceptValue
    }

    @objc func didPressConfirmButton() {
        if internalView.checkmarkButton.isSelected {
            pauseController.hidePauseInformationScreen()
        }
        listener?.pauseConfirmationWantsPauseOptions()
    }

    @objc func didPressCancelButton() {
        listener?.pauseConfirmationWantsDismissal(shouldDismissViewController: true)
    }

    // MARK: - Private

    private lazy var internalView: PauseConfirmationView = PauseConfirmationView(theme: self.theme)
    private lazy var closeBarButtonItem = UIBarButtonItem.closeButton(target: self, action: #selector(didTapCloseButton))
    private let pauseController: PauseControlling

    @objc private func didTapCloseButton(sender: UIBarButtonItem) {
        listener?.pauseConfirmationWantsDismissal(shouldDismissViewController: true)
    }
}

private final class PauseConfirmationView: View {

    private lazy var scrollableStackView = ScrollableStackView(theme: theme)

    override init(theme: Theme) {
        super.init(theme: theme)

        hasBottomMargin = true
    }

    lazy var titleLabel: Label = {
        let label = Label(frame: .zero)
        label.font = theme.fonts.title3
        label.text = .moreInformationSettingsPauseSubtitle
        label.textColor = theme.colors.textPrimary
        label.numberOfLines = 0
        label.accessibilityTraits = .header
        return label
    }()

    lazy var descriptionLabel: Label = {
        let label = Label(frame: .zero)
        label.font = theme.fonts.body
        label.text = .moreInformationSettingsPauseDescription
        label.textColor = theme.colors.textSecondary
        label.numberOfLines = 0
        return label
    }()

    lazy var checkmarkButton: CheckmarkButton = {
        let button = CheckmarkButton(theme: theme)
        button.accessibilityLabel = .moreInformationSettingsPauseDontShowScreen
        button.label.text = .moreInformationSettingsPauseDontShowScreen
        return button
    }()

    lazy var confirmButton: Button = {
        let button = Button(theme: self.theme)
        button.titleEdgeInsets = UIEdgeInsets(top: 40, left: 41, bottom: 40, right: 41)
        button.layer.cornerRadius = 8
        button.setTitle(.moreInformationSettingsPauseYesPause, for: .normal)
        button.style = .primary
        return button
    }()

    lazy var cancelButton: Button = {
        let button = Button(theme: self.theme)
        button.titleEdgeInsets = UIEdgeInsets(top: 40, left: 41, bottom: 40, right: 41)
        button.layer.cornerRadius = 8
        button.setTitle(.moreInformationSettingsPauseNoCancelPause, for: .normal)
        button.style = .secondary
        return button
    }()

    // MARK: - Overrides

    override func build() {
        super.build()

        backgroundColor = theme.colors.viewControllerBackground
        
        addSubview(scrollableStackView)
        scrollableStackView.spacing = 21
        scrollableStackView.addSections([
            titleLabel,
            descriptionLabel
        ])

        addSubview(checkmarkButton)
        addSubview(confirmButton)
        addSubview(cancelButton)
    }

    override func setupConstraints() {
        super.setupConstraints()

        scrollableStackView.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(safeAreaLayoutGuide).inset(16)
            maker.top.equalToSuperview()
            maker.bottom.equalTo(checkmarkButton.snp.top).offset(-16)
        }

        checkmarkButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(safeAreaLayoutGuide).inset(16)
        }

        confirmButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(safeAreaLayoutGuide).inset(16)
            maker.top.equalTo(checkmarkButton.snp.bottom).offset(16)
            maker.bottom.equalTo(cancelButton.snp.top).inset(-16)
            maker.height.equalTo(48)
        }

        cancelButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(safeAreaLayoutGuide).inset(16)
            constrainToSafeLayoutGuidesWithBottomMargin(maker: maker)
            maker.height.equalTo(48)
        }
    }
}
