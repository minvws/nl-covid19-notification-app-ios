/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

/// @mockable
protocol DashboardViewControllable: ViewControllable, DashboardOverviewListener {
    var router: DashboardRouting? { get set }

    func push(viewController: ViewControllable, animated: Bool)
    func cleanNavigationStackIfNeeded()
}

final class DashboardRouter: Router<DashboardViewControllable>, DashboardRouting {

    // MARK: - Initialisation

    init(viewController: DashboardViewControllable,
         overviewBuilder: DashboardOverviewBuildable) {
        self.overviewBuilder = overviewBuilder

        super.init(viewController: viewController)

        viewController.router = self
    }

    func routeToOverview() {
        guard overviewViewController == nil else { return }

        let overviewViewController = overviewBuilder.build(withListener: viewController)
        self.overviewViewController = overviewViewController

        viewController.push(viewController: overviewViewController, animated: false)
    }

    // MARK: - Private

    private let overviewBuilder: DashboardOverviewBuildable
    private var overviewViewController: ViewControllable?
}
