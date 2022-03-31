/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

/// @mockable
protocol DashboardDetailViewControllable: ViewControllable, DashboardOverviewListener {
    var router: DashboardDetailRouting? { get set }

    func push(viewController: ViewControllable, animated: Bool)
    func cleanNavigationStackIfNeeded()
}

final class DashboardDetailRouter: Router<DashboardDetailViewControllable>, DashboardDetailRouting {

    // MARK: - Initialisation

    init(viewController: DashboardDetailViewControllable,
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
