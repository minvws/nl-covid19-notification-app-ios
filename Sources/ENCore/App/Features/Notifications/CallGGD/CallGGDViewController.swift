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
protocol CallGGDViewControllable: ViewControllable {}

final class CallGGDViewController: ViewController, CallGGDViewControllable, UIAdaptivePresentationControllerDelegate {

    init(listener: CallGGDListener,
         theme: Theme,
         interfaceOrientationStream: InterfaceOrientationStreaming) {
        self.listener = listener
        self.interfaceOrientationStream = interfaceOrientationStream

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
        title = .notificationUploadFailedHeader
        navigationItem.rightBarButtonItem = UIBarButtonItem.closeButton(target: self, action: #selector(didTapCloseButton(sender:)))

        internalView.showVisual = !(interfaceOrientationStream.currentOrientationIsLandscape ?? false)
        interfaceOrientationStream
            .isLandscape
            .subscribe { [weak self] isLandscape in
                self?.internalView.showVisual = !isLandscape
            }.disposed(by: disposeBag)
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        listener?.callGGDWantsDismissal(shouldDismissViewController: false)
    }

    // MARK: - Private

    private weak var listener: CallGGDListener?
    private lazy var internalView: CallGGDView = CallGGDView(theme: self.theme)
    private let interfaceOrientationStream: InterfaceOrientationStreaming
    private var disposeBag = DisposeBag()

    @objc private func didTapCloseButton(sender: UIBarButtonItem) {
        listener?.callGGDWantsDismissal(shouldDismissViewController: true)
    }
}

private final class CallGGDView: View {

    fileprivate let infoView: InfoView

    var showVisual: Bool = true {
        didSet {
            infoView.showHeader = showVisual
        }
    }

    // MARK: - Init

    override init(theme: Theme) {
        let config = InfoViewConfig(headerImage: .callGGD,
                                    headerBackgroundViewColor: theme.colors.viewControllerBackground,
                                    showButtons: false)
        self.infoView = InfoView(theme: theme, config: config)
        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        infoView.addSections([
            InfoSectionTextView(theme: theme,
                                title: .notificationUploadFailedTitle,
                                content: .makeFromHtml(text: .notificationUploadFailedContent,
                                                       font: theme.fonts.body,
                                                       textColor: theme.colors.textSecondary,
                                                       textAlignment: Localization.textAlignment))
        ])

        addSubview(infoView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        infoView.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.leading.trailing.equalTo(safeAreaLayoutGuide)
            maker.top.bottom.equalToSuperview()
        }
    }
}
