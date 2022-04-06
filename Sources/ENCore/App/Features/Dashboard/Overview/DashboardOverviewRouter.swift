/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

/// @mockable
protocol DashboardOverviewViewControllable: ViewControllable {}

final class DashboardOverviewRouter: Router<DashboardOverviewViewControllable>, DashboardOverviewRouting {

    // MARK: - Initialisation

    init(listener: DashboardOverviewListener,
         viewController: DashboardOverviewViewControllable /* ,
          childBuilder: ChildBuildable */ ) {
        self.listener = listener
        // self.childBuilder = childBuilder

        super.init(viewController: viewController)
    }

    // MARK: - Private

    private weak var listener: DashboardOverviewListener?
}
