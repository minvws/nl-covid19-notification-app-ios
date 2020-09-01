/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import SnapKit
import UIKit

/// @mockable
protocol CallGGDViewControllable: ViewControllable {}

final class CallGGDViewController: ViewController, CallGGDViewControllable, UIAdaptivePresentationControllerDelegate {

    init(listener: CallGGDListener, theme: Theme) {
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
        title = .notificationUploadFailedHeader
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close,
                                                            target: self,
                                                            action: #selector(didTapCloseButton(sender:)))
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        listener?.callGGDWantsDismissal(shouldDismissViewController: false)
    }

    // MARK: - Private

    private weak var listener: CallGGDListener?
    private lazy var internalView: CallGGDView = CallGGDView(theme: self.theme)

    @objc private func didTapCloseButton(sender: UIBarButtonItem) {
        listener?.callGGDWantsDismissal(shouldDismissViewController: true)
    }
}

private final class CallGGDView: View {

    fileprivate let infoView: InfoView

    // MARK: - Init

    override init(theme: Theme) {
        let config = InfoViewConfig(headerImage: .callGGD,
                                    showButtons: false)
        self.infoView = InfoView(theme: theme, config: config)
        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        infoView.addSections([
            InfoSectionTextView(theme: theme, title: .notificationUploadFailedTitle,
                                content: [NSAttributedString(string: .notificationUploadFailedContent)])
        ])

        addSubview(infoView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        infoView.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.edges.equalToSuperview()
        }
    }
}
