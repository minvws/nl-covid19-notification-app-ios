/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import SnapKit
import UIKit
import WebKit

/// @mockable
protocol AboutRouting: Routing {}

final class AboutViewController: ViewController, AboutViewControllable {
    weak var router: AboutRouting?

    init(listener: AboutListener, theme: Theme) {
        self.listener = listener
        super.init(theme: theme)
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        listener?.aboutRequestsDismissal(shouldHideViewController: false)
    }

    // MARK: - ViewController Lifecycle

    override func loadView() {
        self.view = internalView
        self.view.frame = UIScreen.main.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        modalPresentationStyle = .popover

        navigationItem.rightBarButtonItem = closeBarButtonItem
    }

    @objc func didTapClose() {
        listener?.aboutRequestsDismissal(shouldHideViewController: true)
    }

    // MARK: - Private

    private weak var listener: AboutListener?
    private lazy var internalView: AboutView = AboutView(theme: self.theme)
    private lazy var closeBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close,
                                                          target: self,
                                                          action: #selector(didTapClose))
}

private final class AboutView: View {}
