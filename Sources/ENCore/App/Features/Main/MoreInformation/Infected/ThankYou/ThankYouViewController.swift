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
         interfaceOrientationStream: InterfaceOrientationStreaming) {
        self.listener = listener
        self.exposureConfirmationKey = exposureConfirmationKey
        self.interfaceOrientationStream = interfaceOrientationStream

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
            }.disposed(by: rxDisposeBag)
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        listener?.thankYouWantsDismissal()
    }

    // MARK: - Private

    private weak var listener: ThankYouListener?
    private lazy var internalView: ThankYouView = ThankYouView(theme: self.theme, exposureConfirmationKey: exposureConfirmationKey)
    private let exposureConfirmationKey: ExposureConfirmationKey
    private let interfaceOrientationStream: InterfaceOrientationStreaming
    private var rxDisposeBag = DisposeBag()

    @objc private func didTapCloseButton(sender: UIBarButtonItem) {
        listener?.thankYouWantsDismissal()
    }
}

private final class ThankYouView: View {

    fileprivate let infoView: InfoView
    private let exposureConfirmationKey: ExposureConfirmationKey

    var showVisual: Bool = true {
        didSet {
            infoView.showHeader = showVisual
        }
    }

    // MARK: - Init

    // TODO: Remove exposureConfirmationKey from init and make it settable
    init(theme: Theme, exposureConfirmationKey: ExposureConfirmationKey) {
        let config = InfoViewConfig(actionButtonTitle: .close,
                                    headerImage: .thankYouHeader)
        self.infoView = InfoView(theme: theme, config: config)
        self.exposureConfirmationKey = exposureConfirmationKey
        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        let header = String.moreInformationThankYouSectionHeader.attributed()
        let footer = NSMutableAttributedString(string: "\n")
        footer.append(NSAttributedString.make(
            text: String(format: .moreInformationThankYouSectionFooter, "\n"),
            font: theme.fonts.bodyBold,
            lineHeight: 5))

        footer.append(
            NSAttributedString.make(
                text: String(exposureConfirmationKey.key),
                font: theme.fonts.body,
                letterSpacing: 5))

        var string = [NSAttributedString]()
        string.append(header)
        string.append(footer)

        let view = InfoSectionTextView(theme: theme,
                                       title: .moreInformationThankYouSectionTitle,
                                       content: string)

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
        let string = NSAttributedString.make(text: .moreInformationThankYouInfo, font: theme.fonts.subhead, textColor: theme.colors.gray)
        return InfoSectionCalloutView(theme: theme, content: string)
    }
}
