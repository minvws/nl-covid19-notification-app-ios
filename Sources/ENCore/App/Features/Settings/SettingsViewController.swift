/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import UIKit

/// @mockable
protocol SettingsRouting: Routing {
    func routeToOverview()
    func routeToMobileData()
}

final class SettingsViewController: NavigationController, SettingsViewControllable, UIAdaptivePresentationControllerDelegate {

    weak var router: SettingsRouting?

    // MARK: - Init

    init(listener: SettingsListener,
         theme: Theme) {
        self.listener = listener
        super.init(theme: theme)

        modalPresentationStyle = .popover
        navigationItem.rightBarButtonItem = closeBarButtonItem
        presentationController?.delegate = self
    }

    // MARK: - ViewController Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = .moreInformationSettingsTitle
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        router?.routeToOverview()
    }

    func mobileDataWantsDismissal(shouldDismissViewController: Bool) {
        listener?.settingsWantsDismissal(shouldDismissViewController: true)
    }

    func settingsOverviewRequestsRoutingToMobileData() {
        router?.routeToMobileData()
    }

    // MARK: - SettingsViewControllable

    func push(viewController: ViewControllable, animated: Bool) {
        pushViewController(viewController.uiviewController, animated: animated)
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        listener?.settingsWantsDismissal(shouldDismissViewController: false)
    }

    func cleanNavigationStackIfNeeded() {
        if let first = viewControllers.first, let last = viewControllers.last {
            if first != last {
                viewControllers = [first, last]
            }
        }
    }

    // MARK: - Private

    private weak var listener: SettingsListener?

    @objc private func didTapCloseButton(sender: UIBarButtonItem) {
        listener?.settingsWantsDismissal(shouldDismissViewController: true)
    }

    private lazy var closeBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(didTapCloseButton))
}
