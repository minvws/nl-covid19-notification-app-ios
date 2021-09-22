/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import RxSwift
import SnapKit
import UIKit

/// @mockable
protocol ThankYouViewControllable: ViewControllable {}

final class ThankYouViewController: ViewController, ThankYouViewControllable, UIAdaptivePresentationControllerDelegate {

    // MARK: - Init

    init(listener: ThankYouListener,
         theme: Theme,
         exposureConfirmationKey: ExposureConfirmationKey,
         interfaceOrientationStream: InterfaceOrientationStreaming,
         featureFlagController: FeatureFlagControlling) {
        self.listener = listener
        self.exposureConfirmationKey = exposureConfirmationKey
        self.interfaceOrientationStream = interfaceOrientationStream
        self.featureFlagController = featureFlagController

        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func loadView() {
        self.view = internalView
        self.view.frame = UIScreen.main.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        hasBottomMargin = true
        title = .moreInformationThankYouTitle
        navigationItem.hidesBackButton = true
        navigationItem.rightBarButtonItem = UIBarButtonItem.closeButton(target: self, action: #selector(didTapCloseButton(sender:)))

        internalView.infoView.actionHandler = { [weak self] in
            self?.listener?.thankYouWantsDismissal()
        }

        internalView.showVisual = !(interfaceOrientationStream.currentOrientationIsLandscape ?? false)

        interfaceOrientationStream
            .isLandscape
            .subscribe { [weak self] isLandscape in
                self?.internalView.showVisual = !isLandscape
            }.disposed(by: disposeBag)
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        listener?.thankYouWantsDismissal()
    }

    // MARK: - Private

    private weak var listener: ThankYouListener?
    private lazy var internalView: ThankYouView = ThankYouView(theme: self.theme, exposureConfirmationKey: exposureConfirmationKey, featureFlagController: featureFlagController)
    private let exposureConfirmationKey: ExposureConfirmationKey
    private let interfaceOrientationStream: InterfaceOrientationStreaming
    private let featureFlagController: FeatureFlagControlling
    private var disposeBag = DisposeBag()

    @objc private func didTapCloseButton(sender: UIBarButtonItem) {
        listener?.thankYouWantsDismissal()
    }
}

private final class ThankYouView: View {

    fileprivate let infoView: InfoView
    private let exposureConfirmationKey: ExposureConfirmationKey
    private let featureFlagController: FeatureFlagControlling

    var showVisual: Bool = true {
        didSet {
            infoView.showHeader = showVisual
        }
    }

    // MARK: - Init

    init(theme: Theme,
         exposureConfirmationKey: ExposureConfirmationKey,
         featureFlagController: FeatureFlagControlling) {
        let config = InfoViewConfig(actionButtonTitle: .close,
                                    headerImage: .thankYouHeader,
                                    headerBackgroundViewColor: theme.colors.viewControllerBackground)
        self.infoView = InfoView(theme: theme, config: config, itemSpacing: 8)
        self.exposureConfirmationKey = exposureConfirmationKey
        self.featureFlagController = featureFlagController
        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        let content = NSMutableAttributedString()
        content.append(.makeFromHtml(text: .moreInformationKeySharingThankYouContent, font: theme.fonts.body, textColor: theme.colors.textPrimary, textAlignment: Localization.textAlignment))
        content.append(NSMutableAttributedString(string: "\n"))

        content.append(
            NSAttributedString.make(
                text: String(format: .moreInformationThankYouSectionFooter, ""),
                font: theme.fonts.bodyBold,
                textColor: theme.colors.textPrimary,
                textAlignment: Localization.isRTL ? .right : .left,
                lineHeight: 5))

        content.append(
            NSAttributedString.make(
                text: String(exposureConfirmationKey.key.asGGDkey),
                font: theme.fonts.body,
                textColor: theme.colors.textPrimary,
                textAlignment: Localization.isRTL ? .right : .left))

        let view = InfoSectionTextView(theme: theme,
                                       title: .moreInformationKeySharingThankYouTitle,
                                       content: content)

        infoView.addSections([view, info()])

        addSubview(infoView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        infoView.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.leading.trailing.equalTo(safeAreaLayoutGuide)
            maker.top.bottom.equalToSuperview()
        }
    }

    private func info() -> View {
        let string = NSAttributedString.make(
            text: featureFlagController.isFeatureFlagEnabled(feature: .independentKeySharing)
                ? .moreInformationKeySharingThankYouConfirmation
                : .moreInformationThankYouInfo,
            font: theme.fonts.subhead(limitMaximumSize: false),
            textColor: theme.colors.textPrimary,
            textAlignment: Localization.isRTL ? .right : .left)
        return InfoSectionCalloutView(theme: theme, content: string)
    }
}
