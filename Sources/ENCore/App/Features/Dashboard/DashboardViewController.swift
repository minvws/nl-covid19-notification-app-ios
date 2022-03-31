/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import UIKit

/// @mockable
protocol DashboardRouting: Routing {
    func routeToOverview()
}

final class DashboardViewController: NavigationController, DashboardViewControllable, UIAdaptivePresentationControllerDelegate {

    weak var router: DashboardRouting?

    init(listener: DashboardListener, theme: Theme, identifier: DashboardIdentifier) {
        self.listener = listener
        self.startIdentifer = identifier
        super.init(theme: theme)

        navigationItem.rightBarButtonItem = closeBarButtonItem
        presentationController?.delegate = self
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        listener?.dashboardRequestsDismissal(shouldDismissViewController: false)
    }

    @objc func didTapClose() {
        listener?.dashboardRequestsDismissal(shouldDismissViewController: true)
    }

    // MARK: - DashboardViewControllable

    func push(viewController: ViewControllable, animated: Bool) {
        pushViewController(viewController.uiviewController, animated: animated)
    }

    func cleanNavigationStackIfNeeded() {
        if let first = viewControllers.first, let last = viewControllers.last {
            if first != last {
                viewControllers = [first, last]
            }
        }
    }

    // MARK: - ViewController Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        router?.routeToOverview()
    }

    // MARK: - Private

    private let startIdentifer: DashboardIdentifier
    private weak var listener: DashboardListener?
    private lazy var closeBarButtonItem = UIBarButtonItem.closeButton(target: self, action: #selector(didTapClose))
}
