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

/// @mockable
protocol MobileDataViewControllable: ViewControllable {}

final class MobileDataViewController: ViewController, MobileDataViewControllable, UIAdaptivePresentationControllerDelegate, Logging {

    // MARK: - Init

    init(listener: MobileDataListener,
         theme: Theme) {
        self.listener = listener
        super.init(theme: theme)
    }

    // MARK: - ViewController Lifecycle

    override func loadView() {
        self.view = internalView
        self.view.frame = UIScreen.main.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        hasBottomMargin = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(didTapCloseButton(sender:)))

        internalView.buttonActionHandler = { [weak self] in
            guard let url = URL(string: UIApplication.openSettingsURLString) else {
                self?.logDebug("Cannot open app using: \(UIApplication.openSettingsURLString)")
                return
            }

            UIApplication.shared.open(url,
                                      options: [:],
                                      completionHandler: nil)
        }
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        listener?.mobileDataWantsDismissal(shouldDismissViewController: false)
    }

    // MARK: - Private

    private weak var listener: MobileDataListener?
    private lazy var internalView: MobileDataView = MobileDataView(theme: self.theme)

    @objc private func didTapCloseButton(sender: UIBarButtonItem) {
        listener?.mobileDataWantsDismissal(shouldDismissViewController: true)
    }
}

private final class MobileDataView: View {

    private let infoView: InfoView
    var buttonActionHandler: (() -> ())? {
        get { infoView.actionHandler }
        set { infoView.actionHandler = newValue }
    }
    private let model: EnableSettingModel
    private var stepViews: [View] = []

    // MARK: - Init

    override init(theme: Theme) {

        model = .enableMobileDataUsage(theme)

        let config = InfoViewConfig(actionButtonTitle: self.model.actionTitle,
                                    secondaryButtonTitle: nil,
                                    headerImage: nil,
                                    stickyButtons: true)
        infoView = InfoView(theme: theme, config: config, itemSpacing: 15)
        infoView.showHeader = false
        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        infoView.addSections([
            titleLabel,
            settingsDescription
        ])

        var stepIndex = 0

        model.steps.forEach { model in
            stepIndex += 1
            infoView.addSections([
                EnableSettingStepView(theme: theme, step: model, stepIndex: stepIndex)
            ])
        }

        addSubview(infoView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        infoView.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.leading.trailing.equalTo(safeAreaLayoutGuide)
            maker.top.bottom.equalToSuperview()
        }
    }

    // MARK: - Private

    lazy var titleLabel: View = {
        InfoSectionTextView(theme: theme,
                            title: "",
                            content: [
                                .makeFromHtml(text: .moreInformationSettingsMobileDataTitle,
                                              font: theme.fonts.largeTitle,
                                              textColor: theme.colors.gray,
                                              textAlignment: Localization.isRTL ? .right : .left)
                            ],
                            contentAccessibilityTraits: .header)
    }()

    private lazy var settingsDescription: View = {
        InfoSectionTextView(theme: theme,
                            title: "",
                            content: [NSAttributedString.makeFromHtml(text: .moreInformationSettingsDescription, font: theme.fonts.body, textColor: theme.colors.gray)])
    }()
}
